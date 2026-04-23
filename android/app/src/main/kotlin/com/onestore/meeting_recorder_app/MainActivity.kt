package com.onestore.meeting_recorder_app

import android.util.Log
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import org.json.JSONArray
import org.json.JSONObject
import java.io.File
import java.io.FileOutputStream
import java.io.IOException
import java.net.HttpURLConnection
import java.net.URL
import java.nio.charset.Charset
import kotlin.math.roundToInt

class MainActivity : FlutterActivity() {
    private val channelName = "meeting_recorder/local_stt"
    private val tag = "LOCAL_STT"
    private lateinit var methodChannel: MethodChannel

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        methodChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName)
        methodChannel.setMethodCallHandler { call: MethodCall, result: MethodChannel.Result ->
            when (call.method) {
                "transcribe" -> handleTranscribe(call, result)
                "installFromUrls" -> handleInstallFromUrls(call, result)
                "installBundledWhisperAndModel" -> handleInstallBundledWhisperAndModel(call, result)
                "verifySetup" -> handleVerifySetup(call, result)
                else -> result.notImplemented()
            }
        }
    }

    private fun copyAssetToFile(assetPath: String, output: File) {
        output.parentFile?.mkdirs()
        try {
            assets.open(assetPath).use { input ->
                FileOutputStream(output).use { out ->
                    val buffer = ByteArray(1024 * 32)
                    var read = input.read(buffer)
                    while (read >= 0) {
                        if (read > 0) {
                            out.write(buffer, 0, read)
                        }
                        read = input.read(buffer)
                    }
                    out.flush()
                }
            }
        } catch (t: Throwable) {
            if (t is IOException) {
                throw IllegalStateException(
                    "bundled asset missing: $assetPath " +
                        "(place binary at android/app/src/main/assets/$assetPath)"
                )
            }
            throw t
        }
    }

    private fun emitInstallProgress(step: String, progress: Int, message: String) {
        runOnUiThread {
            methodChannel.invokeMethod(
                "installProgress",
                hashMapOf(
                    "step" to step,
                    "progress" to progress.coerceIn(0, 100),
                    "message" to message
                )
            )
        }
        Log.i(tag, "progress step=$step progress=$progress message=$message")
    }

    private fun estimateProgress(
        downloaded: Long,
        total: Long,
        startPercent: Int,
        endPercent: Int
    ): Int {
        if (total <= 0L) {
            return startPercent
        }
        val ratio = downloaded.toDouble() / total.toDouble()
        val p = startPercent + ((endPercent - startPercent) * ratio).roundToInt()
        return p.coerceIn(startPercent, endPercent)
    }

    private fun downloadToFile(
        url: String,
        output: File,
        phase: String,
        startPercent: Int,
        endPercent: Int
    ) {
        Log.i(tag, "downloadToFile request=$url")
        emitInstallProgress(phase, startPercent, "Download started")
        val connection = URL(url).openConnection() as HttpURLConnection
        connection.instanceFollowRedirects = true
        connection.connectTimeout = 20000
        connection.readTimeout = 600000
        connection.requestMethod = "GET"
        connection.setRequestProperty("User-Agent", "MeetingRecorderApp/1.0 (Android)")
        connection.setRequestProperty("Accept", "*/*")
        connection.connect()
        Log.i(tag, "downloadToFile responseCode=${connection.responseCode} finalUrl=${connection.url}")
        if (connection.responseCode !in 200..299) {
            val errorText = try {
                connection.errorStream?.bufferedReader(Charset.forName("UTF-8"))?.readText().orEmpty()
            } catch (_: Throwable) {
                ""
            }
            Log.e(tag, "downloadToFile failed code=${connection.responseCode} body=$errorText")
            throw IllegalStateException(
                "download failed(${connection.responseCode}): $url ${if (errorText.isNotBlank()) "| $errorText" else ""}"
            )
        }

        val totalBytes = connection.contentLengthLong
        connection.inputStream.use { input ->
            FileOutputStream(output).use { out ->
                val buffer = ByteArray(1024 * 32)
                var downloaded = 0L
                var read = input.read(buffer)
                while (read >= 0) {
                    if (read > 0) {
                        out.write(buffer, 0, read)
                        downloaded += read.toLong()
                        val progress = estimateProgress(downloaded, totalBytes, startPercent, endPercent)
                        emitInstallProgress(phase, progress, "Downloading")
                    }
                    read = input.read(buffer)
                }
                out.flush()
            }
        }
        emitInstallProgress(phase, endPercent, "Download complete")
        Log.i(tag, "downloadToFile saved=${output.absolutePath} size=${output.length()}")
        connection.disconnect()
    }

    private fun handleVerifySetup(call: MethodCall, result: MethodChannel.Result) {
        val whisperBinPath = call.argument<String>("whisperBinPath").orEmpty().trim()
        val modelPath = call.argument<String>("modelPath").orEmpty().trim()
        val ok = whisperBinPath.isNotEmpty() &&
            modelPath.isNotEmpty() &&
            File(whisperBinPath).exists() &&
            File(modelPath).exists()
        result.success(ok)
    }

    private fun handleInstallFromUrls(call: MethodCall, result: MethodChannel.Result) {
        Thread {
            try {
                val whisperBinUrl = call.argument<String>("whisperBinUrl").orEmpty().trim()
                val modelUrl = call.argument<String>("modelUrl").orEmpty().trim()
                val whisperBinPath = call.argument<String>("whisperBinPath").orEmpty().trim()
                val modelPath = call.argument<String>("modelPath").orEmpty().trim()

                Log.i(tag, "installFromUrls start")
                Log.i(tag, "whisperBinUrl=$whisperBinUrl")
                Log.i(tag, "modelUrl=$modelUrl")
                Log.i(tag, "whisperBinPath=$whisperBinPath")
                Log.i(tag, "modelPath=$modelPath")

                if (whisperBinUrl.isEmpty() || modelUrl.isEmpty()) {
                    runOnUiThread {
                        result.error("LOCAL_STT_INSTALL_ARG", "whisperBinUrl/modelUrl are required", null)
                    }
                    return@Thread
                }
                if (whisperBinPath.isEmpty() || modelPath.isEmpty()) {
                    runOnUiThread {
                        result.error("LOCAL_STT_INSTALL_ARG", "whisperBinPath/modelPath are required", null)
                    }
                    return@Thread
                }

                val whisperBinFile = File(whisperBinPath)
                whisperBinFile.parentFile?.mkdirs()
                downloadToFile(
                    url = whisperBinUrl,
                    output = whisperBinFile,
                    phase = "whisper",
                    startPercent = 5,
                    endPercent = 45
                )
                whisperBinFile.setExecutable(true)
                emitInstallProgress("whisper", 50, "whisper-cli executable")

                val modelFile = File(modelPath)
                modelFile.parentFile?.mkdirs()
                downloadToFile(
                    url = modelUrl,
                    output = modelFile,
                    phase = "model",
                    startPercent = 55,
                    endPercent = 95
                )
                emitInstallProgress("finalize", 100, "Install complete")

                val payload = hashMapOf(
                    "whisperBinPath" to whisperBinFile.absolutePath,
                    "modelPath" to modelFile.absolutePath
                )
                runOnUiThread { result.success(payload) }
            } catch (t: Throwable) {
                Log.e(tag, "installFromUrls failed", t)
                runOnUiThread { result.error("LOCAL_STT_INSTALL_FAIL", t.message, null) }
            }
        }.start()
    }

    private fun handleInstallBundledWhisperAndModel(call: MethodCall, result: MethodChannel.Result) {
        Thread {
            try {
                val modelUrl = call.argument<String>("modelUrl").orEmpty().trim()
                val whisperBinPath = call.argument<String>("whisperBinPath").orEmpty().trim()
                val modelPath = call.argument<String>("modelPath").orEmpty().trim()

                if (whisperBinPath.isEmpty() || modelPath.isEmpty()) {
                    runOnUiThread {
                        result.error("LOCAL_STT_INSTALL_ARG", "whisperBinPath/modelPath are required", null)
                    }
                    return@Thread
                }

                emitInstallProgress("whisper", 5, "Preparing bundled whisper-cli")
                val nativeLibBin = File(applicationInfo.nativeLibraryDir, "libwhisper_cli.so")
                if (!nativeLibBin.exists()) {
                    runOnUiThread {
                        result.error(
                            "LOCAL_STT_INSTALL_FAIL",
                            "bundled native whisper binary missing: ${nativeLibBin.absolutePath}",
                            null
                        )
                    }
                    return@Thread
                }
                Log.i(tag, "Using bundled native whisper binary: ${nativeLibBin.absolutePath}")
                val whisperBinFile = nativeLibBin
                whisperBinFile.setExecutable(true, false)
                emitInstallProgress("whisper", 50, "Bundled whisper-cli ready")

                val modelFile = File(modelPath)
                modelFile.parentFile?.mkdirs()
                if (modelUrl.isEmpty()) {
                    emitInstallProgress("model", 55, "Preparing bundled model")
                    copyAssetToFile(
                        assetPath = "whisper/models/ggml-base.bin",
                        output = modelFile
                    )
                    emitInstallProgress("model", 95, "Bundled model ready")
                } else {
                    downloadToFile(
                        url = modelUrl,
                        output = modelFile,
                        phase = "model",
                        startPercent = 55,
                        endPercent = 95
                    )
                }
                emitInstallProgress("finalize", 100, "Install complete")

                val payload = hashMapOf(
                    "whisperBinPath" to whisperBinFile.absolutePath,
                    "modelPath" to modelFile.absolutePath
                )
                runOnUiThread { result.success(payload) }
            } catch (t: Throwable) {
                Log.e(tag, "installBundledWhisperAndModel failed", t)
                runOnUiThread { result.error("LOCAL_STT_INSTALL_FAIL", t.message, null) }
            }
        }.start()
    }

    private fun handleTranscribe(call: MethodCall, result: MethodChannel.Result) {
        Thread {
            try {
                val audioPath = call.argument<String>("filePath").orEmpty().trim()
                val whisperBinPath = call.argument<String>("whisperBinPath").orEmpty().trim()
                val modelPath = call.argument<String>("modelPath").orEmpty().trim()
                val language = call.argument<String>("language").orEmpty().ifEmpty { "ko" }

                if (audioPath.isEmpty()) {
                    runOnUiThread { result.error("LOCAL_STT_ARG", "filePath is required", null) }
                    return@Thread
                }

                val audioFile = File(audioPath)
                if (!audioFile.exists()) {
                    runOnUiThread { result.error("LOCAL_STT_FILE", "audio file not found: $audioPath", null) }
                    return@Thread
                }

                val requestedWhisperBin = File(whisperBinPath)
                val nativeLibBin = File(applicationInfo.nativeLibraryDir, "libwhisper_cli.so")
                val whisperBin = if (nativeLibBin.exists()) {
                    Log.i(tag, "Transcribe uses bundled native whisper binary: ${nativeLibBin.absolutePath}")
                    nativeLibBin
                } else {
                    requestedWhisperBin
                }
                if (!whisperBin.exists()) {
                    runOnUiThread {
                        result.error(
                            "LOCAL_STT_BIN",
                            "whisper-cli not found (native=${nativeLibBin.absolutePath}, requested=$whisperBinPath)",
                            null
                        )
                    }
                    return@Thread
                }
                whisperBin.setExecutable(true)

                val modelFile = File(modelPath)
                if (!modelFile.exists()) {
                    runOnUiThread { result.error("LOCAL_STT_MODEL", "model file not found: $modelPath", null) }
                    return@Thread
                }

                val outBase = File(filesDir, "stt_${System.currentTimeMillis()}").absolutePath
                val command = listOf(
                    whisperBin.absolutePath,
                    "-m", modelFile.absolutePath,
                    "-f", audioFile.absolutePath,
                    "-l", language,
                    "-oj", "-otxt",
                    "-of", outBase,
                    "-tdrz"
                )

                val processBuilder = ProcessBuilder(command).redirectErrorStream(true)
                val env = processBuilder.environment()
                val nativeLibDir = applicationInfo.nativeLibraryDir
                val currentLdPath = env["LD_LIBRARY_PATH"].orEmpty()
                env["LD_LIBRARY_PATH"] = if (currentLdPath.isBlank()) {
                    nativeLibDir
                } else {
                    "$nativeLibDir:$currentLdPath"
                }
                Log.i(tag, "Transcribe LD_LIBRARY_PATH=${env["LD_LIBRARY_PATH"]}")

                val process = processBuilder.start()

                val output = process.inputStream.bufferedReader(Charset.forName("UTF-8")).readText()
                val exitCode = process.waitFor()
                Log.i(tag, "whisper-cli finished exitCode=$exitCode outputLength=${output.length}")
                if (exitCode != 0) {
                    val preview = if (output.length > 4000) output.take(4000) + "...(truncated)" else output
                    Log.e(tag, "whisper-cli failed($exitCode): $preview")
                    runOnUiThread { result.error("LOCAL_STT_EXEC", "whisper-cli failed($exitCode): $preview", null) }
                    return@Thread
                }

                val jsonFile = File("$outBase.json")
                val txtFile = File("$outBase.txt")
                val parsedFromJsonFile = if (jsonFile.exists()) {
                    parseWhisperJsonSafe(jsonFile.readText(Charset.forName("UTF-8")))
                } else {
                    null
                }
                val parsedFromStdout = parseWhisperJsonSafe(output)
                val parsed = parsedFromJsonFile ?: parsedFromStdout

                var text = parsed?.first
                    ?: if (txtFile.exists()) txtFile.readText(Charset.forName("UTF-8")).trim() else ""
                if (text.isBlank()) {
                    text = extractTextFromCliOutput(output)
                }

                val segments = parsed?.second ?: listOf(
                    hashMapOf(
                        "speaker" to "SPEAKER_00",
                        "start" to 0,
                        "end" to 0,
                        "text" to text
                    )
                )

                val payload = hashMapOf(
                    "text" to text,
                    "language" to language,
                    "segments" to segments
                )
                Log.i(tag, "whisper-cli success textLength=${text.length} segments=${segments.size}")
                runOnUiThread { result.success(payload) }
            } catch (t: Throwable) {
                Log.e(tag, "transcribe failed", t)
                runOnUiThread { result.error("LOCAL_STT_UNKNOWN", t.message, null) }
            }
        }.start()
    }

    private fun parseWhisperJson(raw: String): Pair<String, List<HashMap<String, Any>>> {
        val root = JSONObject(raw)
        val segments = mutableListOf<HashMap<String, Any>>()
        var speakerIdx = 0

        val transcriptionArray = when {
            root.has("transcription") -> root.optJSONArray("transcription")
            root.has("segments") -> root.optJSONArray("segments")
            else -> JSONArray()
        } ?: JSONArray()

        for (i in 0 until transcriptionArray.length()) {
            val item = transcriptionArray.optJSONObject(i) ?: continue
            var text = item.optString("text", "").trim()
            if (text.isEmpty()) continue

            if (text.contains("[SPEAKER_TURN]")) {
                speakerIdx = 1 - speakerIdx
                text = text.replace("[SPEAKER_TURN]", "").trim()
            }

            val start = extractStartSec(item)
            val end = extractEndSec(item, start)
            segments.add(
                hashMapOf(
                    "speaker" to "SPEAKER_${speakerIdx.toString().padStart(2, '0')}",
                    "start" to start,
                    "end" to end,
                    "text" to text
                )
            )
        }

        val text = segments.joinToString(" ") { it["text"].toString() }.trim()
        return text to if (segments.isEmpty()) {
            listOf(
                hashMapOf(
                    "speaker" to "SPEAKER_00",
                    "start" to 0,
                    "end" to 0,
                    "text" to text
                )
            )
        } else {
            segments
        }
    }

    private fun parseWhisperJsonSafe(raw: String): Pair<String, List<HashMap<String, Any>>>? {
        val trimmed = raw.trim()
        if (trimmed.isEmpty()) {
            return null
        }
        return try {
            parseWhisperJson(trimmed)
        } catch (_: Throwable) {
            null
        }
    }

    private fun extractTextFromCliOutput(output: String): String {
        if (output.isBlank()) {
            return ""
        }

        val lines = output
            .lineSequence()
            .map { it.trim() }
            .filter { it.isNotEmpty() }
            .filterNot {
                it.startsWith("whisper_") ||
                    it.startsWith("main:") ||
                    it.startsWith("system_info:") ||
                    it.startsWith("log_mel_spectrogram:") ||
                    it.startsWith("encode:") ||
                    it.startsWith("decode:") ||
                    it.startsWith("timings:")
            }
            .toList()

        if (lines.isEmpty()) {
            return ""
        }

        val timestampRegex = Regex("""^\[[^\]]+\]\s*(.+)$""")
        val cleaned = lines.map { line ->
            val match = timestampRegex.find(line)
            if (match != null && match.groupValues.size > 1) {
                match.groupValues[1].trim()
            } else {
                line
            }
        }.filter { it.isNotEmpty() }

        return cleaned.joinToString(" ").trim()
    }

    private fun extractStartSec(item: JSONObject): Int {
        val offsets = item.optJSONObject("offsets")
        if (offsets != null && offsets.has("from")) {
            return (offsets.optDouble("from", 0.0) / 1000.0).toInt()
        }
        if (item.has("start")) {
            return item.optDouble("start", 0.0).toInt()
        }
        return 0
    }

    private fun extractEndSec(item: JSONObject, fallback: Int): Int {
        val offsets = item.optJSONObject("offsets")
        if (offsets != null && offsets.has("to")) {
            val value = (offsets.optDouble("to", 0.0) / 1000.0).toInt()
            return if (value < fallback) fallback else value
        }
        if (item.has("end")) {
            val value = item.optDouble("end", fallback.toDouble()).toInt()
            return if (value < fallback) fallback else value
        }
        return fallback
    }
}
