import argparse
import json
import math
import os
import sys
from typing import Any, Dict, List, Optional


def _safe_int(value: Any) -> int:
    try:
        return int(math.floor(float(value)))
    except Exception:
        return 0


def run_faster_whisper(audio_path: str, model_name: str, language: str) -> Dict[str, Any]:
    try:
        from faster_whisper import WhisperModel
    except Exception as exc:
        raise RuntimeError(
            "faster-whisper가 설치되어 있지 않습니다. "
            "pip install -r tools/local_stt/requirements.txt 를 먼저 실행해 주세요."
        ) from exc

    model = WhisperModel(model_name, device="cpu", compute_type="int8")
    segments, info = model.transcribe(audio_path, language=language, vad_filter=True)

    rows: List[Dict[str, Any]] = []
    texts: List[str] = []
    for seg in segments:
        text = (seg.text or "").strip()
        if not text:
            continue
        start = _safe_int(getattr(seg, "start", 0))
        end = _safe_int(getattr(seg, "end", 0))
        rows.append(
            {
                "speaker": "SPEAKER_00",
                "start": start,
                "end": max(end, start),
                "text": text,
            }
        )
        texts.append(text)

    return {
        "language": (getattr(info, "language", None) or language or "ko"),
        "text": " ".join(texts).strip(),
        "segments": rows,
    }


def apply_pyannote_diarization(
    audio_path: str,
    base_segments: List[Dict[str, Any]],
    hf_token: Optional[str],
) -> List[Dict[str, Any]]:
    if not hf_token:
        return base_segments

    try:
        from pyannote.audio import Pipeline
    except Exception:
        return base_segments

    try:
        pipeline = Pipeline.from_pretrained("pyannote/speaker-diarization-3.1", use_auth_token=hf_token)
        diarization = pipeline(audio_path)
    except Exception:
        return base_segments

    turns: List[Dict[str, Any]] = []
    for turn, _, speaker in diarization.itertracks(yield_label=True):
        turns.append(
            {
                "speaker": str(speaker),
                "start": float(turn.start),
                "end": float(turn.end),
            }
        )

    if not turns:
        return base_segments

    def choose_speaker(start_sec: int, end_sec: int) -> str:
        best_speaker = "SPEAKER_00"
        best_overlap = 0.0
        for t in turns:
            overlap = max(0.0, min(end_sec, t["end"]) - max(start_sec, t["start"]))
            if overlap > best_overlap:
                best_overlap = overlap
                best_speaker = t["speaker"]
        return best_speaker

    enriched: List[Dict[str, Any]] = []
    for seg in base_segments:
        start_sec = _safe_int(seg.get("start", 0))
        end_sec = _safe_int(seg.get("end", start_sec))
        updated = dict(seg)
        updated["speaker"] = choose_speaker(start_sec, max(end_sec, start_sec))
        enriched.append(updated)
    return enriched


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--input", required=True, help="audio file path")
    parser.add_argument("--model", default="small", help="faster-whisper model (tiny/base/small/medium/large-v3)")
    parser.add_argument("--language", default="ko", help="language code")
    parser.add_argument("--hf-token", default="", help="Hugging Face token for pyannote diarization")
    parser.add_argument("--json", action="store_true", help="print JSON result")
    args = parser.parse_args()

    audio_path = os.path.abspath(args.input)
    if not os.path.exists(audio_path):
        print(f"audio file not found: {audio_path}", file=sys.stderr)
        return 2

    try:
        stt = run_faster_whisper(audio_path, args.model, args.language)
        diarized_segments = apply_pyannote_diarization(
            audio_path=audio_path,
            base_segments=stt["segments"],
            hf_token=(args.hf_token or "").strip(),
        )
        output = {
            "language": stt["language"],
            "text": stt["text"],
            "segments": diarized_segments,
        }
    except Exception as exc:
        print(str(exc), file=sys.stderr)
        return 1

    if args.json:
        print(json.dumps(output, ensure_ascii=False))
    else:
        print(output["text"])
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
