import 'reading_progress.dart';

/// One member of a reading challenge together with their latest progress.
class MemberProgress {
  const MemberProgress({
    required this.uid,
    required this.displayName,
    required this.progress,
  });

  final String uid;
  final String displayName;
  final ReadingProgress progress;

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
