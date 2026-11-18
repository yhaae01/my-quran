import 'mushaf.dart';
import 'reading_progress.dart';

/// State of today's "1 Hari 1 Juz" (1D1J) tilawah target.
///
/// Progress is derived from the reader's actual position: [baselineVerse] is
/// recorded when the day starts, and every verse read afterwards counts towards
/// the target. Manual pages let the reader credit reading that happened outside
/// the app.
class DailyTilawah {
  const DailyTilawah({
    required this.date,
    required this.baselineVerse,
    this.targetPages = defaultTargetPages,
    this.manualPages = 0,
    this.completed = false,
    this.completedAt,
  });

  /// One juz of the Madinah/Kemenag mushaf is 20 pages.
  static const int defaultTargetPages = 20;

  /// 604 mushaf pages over 6,236 verses.
  static const double versesPerPage = totalQuranVerses / mushafPageCount;

  final DateTime date;
  final int baselineVerse;
  final int targetPages;
  final int manualPages;
  final bool completed;
  final DateTime? completedAt;

  static DateTime dayOf(DateTime value) =>
      DateTime(value.year, value.month, value.day);

  static DateTime today() => dayOf(DateTime.now());

  static String dateKeyFor(DateTime value) {
    final day = dayOf(value);
    final month = day.month.toString().padLeft(2, '0');
    final dayOfMonth = day.day.toString().padLeft(2, '0');
    return '${day.year}-$month-$dayOfMonth';
  }

  String get dateKey => dateKeyFor(date);

  /// A target starts where the reader currently is, so the first page of the
  /// day counts from that position instead of the beginning of the Qur'an.
  factory DailyTilawah.startingAt({
    required int baselineVerse,
    DateTime? date,
    int targetPages = defaultTargetPages,
  }) {
    return DailyTilawah(
      date: dayOf(date ?? DateTime.now()),
      baselineVerse: baselineVerse.clamp(0, totalQuranVerses),
      targetPages: targetPages.clamp(1, mushafPageCount),
    );
  }

  bool isForDay(DateTime value) => dateKey == dateKeyFor(value);

  int versesReadSince(ReadingProgress? progress) {
    if (progress == null) return 0;
    return (progress.versesRead - baselineVerse).clamp(0, totalQuranVerses);
  }

  /// Pages read today, including manual credits, capped at the daily target.
  double pagesRead(ReadingProgress? progress) {
    final automatic = versesReadSince(progress) / versesPerPage;
    return (automatic + manualPages).clamp(0, targetPages.toDouble());
  }

  double remainingPages(ReadingProgress? progress) =>
      (targetPages - pagesRead(progress)).clamp(0, targetPages.toDouble());

  double ratioFor(ReadingProgress? progress) =>
      completed ? 1 : (pagesRead(progress) / targetPages).clamp(0.0, 1.0);

  int percentFor(ReadingProgress? progress) =>
      (ratioFor(progress) * 100).round();

  bool isCompleteFor(ReadingProgress? progress) {
    if (completed) return true;
    final automatic = versesReadSince(progress) / versesPerPage;
    return automatic + manualPages >= targetPages;
  }

  /// "20 halaman · 1 juz" for a full juz target.
  String get targetLabel {
    final juz = targetPages / defaultTargetPages;
    final juzText = juz == juz.roundToDouble()
        ? juz.toStringAsFixed(0)
        : juz.toStringAsFixed(1);
    return '$targetPages halaman · $juzText juz';
  }

  DailyTilawah copyWith({
    DateTime? date,
    int? baselineVerse,
    int? targetPages,
    int? manualPages,
    bool? completed,
    DateTime? completedAt,
  }) {
    return DailyTilawah(
      date: date ?? this.date,
      baselineVerse: baselineVerse ?? this.baselineVerse,
      targetPages: targetPages ?? this.targetPages,
      manualPages: manualPages ?? this.manualPages,
      completed: completed ?? this.completed,
      completedAt: completedAt ?? this.completedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'date': dateKey,
      'baseline_verse': baselineVerse,
      'target_pages': targetPages,
      'manual_pages': manualPages,
      'completed': completed,
      'completed_at': completedAt?.toIso8601String(),
    };
  }

  static DailyTilawah? fromMap(Map<dynamic, dynamic>? map, {DateTime? now}) {
    if (map == null) return null;
    final date = DateTime.tryParse(map['date'] as String? ?? '');
    final baseline = map['baseline_verse'];
    if (date == null || baseline is! num) return null;
    final target = map['target_pages'];
    final manual = map['manual_pages'];
    return DailyTilawah(
      date: dayOf(date),
      baselineVerse: baseline.toInt().clamp(0, totalQuranVerses),
      targetPages: target is num
          ? target.toInt().clamp(1, mushafPageCount)
          : defaultTargetPages,
      manualPages: manual is num ? manual.toInt().clamp(0, mushafPageCount) : 0,
      completed: map['completed'] as bool? ?? false,
      completedAt: DateTime.tryParse(map['completed_at'] as String? ?? ''),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is DailyTilawah &&
        other.date == date &&
        other.baselineVerse == baselineVerse &&
        other.targetPages == targetPages &&
        other.manualPages == manualPages &&
        other.completed == completed &&
        other.completedAt == completedAt;
  }

  @override
  int get hashCode => Object.hash(
    date,
    baselineVerse,
    targetPages,
    manualPages,
    completed,
    completedAt,
  );
}
