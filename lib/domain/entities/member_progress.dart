import 'daily_tilawah.dart';
import 'reading_progress.dart';

/// One member of a reading challenge together with their latest progress.
class MemberProgress {
  const MemberProgress({
    required this.uid,
    required this.displayName,
    required this.progress,
    this.dailyPages = 0,
    this.dailyTargetPages = DailyTilawah.defaultTargetPages,
    this.dailyCompleted = false,
    this.dailyDate,
  });

  final String uid;
  final String displayName;
  final ReadingProgress progress;

  /// Today's 1D1J pages and completion, synced with the reading position.
  final double dailyPages;
  final int dailyTargetPages;
  final bool dailyCompleted;
  final String? dailyDate;

  bool get hasDailyTargetToday =>
      dailyDate == DailyTilawah.dateKeyFor(DateTime.now());

  double get dailyRatio =>
      dailyCompleted ? 1 : (dailyPages / dailyTargetPages).clamp(0.0, 1.0);

  int get versesRead => progress.versesRead;

  double get ratio => progress.ratio;

  int get percent => progress.percent;

  String get initials {
    final parts = displayName
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return '${parts.first.substring(0, 1)}${parts[1].substring(0, 1)}'
        .toUpperCase();
  }
}
