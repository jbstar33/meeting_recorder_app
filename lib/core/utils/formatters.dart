import 'package:intl/intl.dart';

String formatDateTime(DateTime value) {
  return DateFormat('yyyy.MM.dd HH:mm').format(value);
}

String formatDuration(int totalSeconds) {
  final Duration duration = Duration(seconds: totalSeconds);
  final int minutes = duration.inMinutes;
  final int seconds = duration.inSeconds.remainder(60);
  if (minutes >= 60) {
    final int hours = duration.inHours;
    final int remainingMinutes = duration.inMinutes.remainder(60);
    return '${hours}h ${remainingMinutes}m';
  }
  return '${minutes}m ${seconds.toString().padLeft(2, '0')}s';
}

String formatRange(int startSeconds, int endSeconds) {
  return '${_formatClock(startSeconds)} - ${_formatClock(endSeconds)}';
}

String _formatClock(int totalSeconds) {
  final int minutes = totalSeconds ~/ 60;
  final int seconds = totalSeconds % 60;
  return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
}
