/// The five daily prayers, in the order they occur.
enum Prayer {
  fajr,
  dhuhr,
  asr,
  maghrib,
  isha;

  String get label => switch (this) {
    Prayer.fajr => 'Subuh',
    Prayer.dhuhr => 'Dzuhur',
    Prayer.asr => 'Ashar',
    Prayer.maghrib => 'Maghrib',
    Prayer.isha => 'Isya',
  };

  String get arabicLabel => switch (this) {
    Prayer.fajr => 'الفجر',
    Prayer.dhuhr => 'الظهر',
    Prayer.asr => 'العصر',
    Prayer.maghrib => 'المغرب',
    Prayer.isha => 'العشاء',
  };

  static Prayer? fromName(String? name) {
    for (final prayer in Prayer.values) {
      if (prayer.name == name) return prayer;
    }
    return null;
  }
}

/// One prayer at an absolute instant (stored in UTC).
class PrayerMoment {
  const PrayerMoment({required this.prayer, required this.instant});

  final Prayer prayer;
  final DateTime instant;

  @override
  bool operator ==(Object other) {
    return other is PrayerMoment &&
        other.prayer == prayer &&
        other.instant.isAtSameMomentAs(instant);
  }

  @override
  int get hashCode => Object.hash(prayer, instant.toUtc());
}

/// All five prayers for one civil date in the selected location.
class PrayerDay {
  const PrayerDay({required this.date, required this.moments});

  /// Civil date at midnight, without a timezone. Read [date].year/month/day
  /// directly instead of converting it with [DateTime.toLocal].
  final DateTime date;
  final List<PrayerMoment> moments;

  PrayerMoment momentFor(Prayer prayer) {
    return moments.firstWhere((moment) => moment.prayer == prayer);
  }
}

/// Seven days of prayer times for one location. Keeping a week lets the
/// reminder scheduler keep working when the app is not opened every day.
class PrayerSchedule {
  const PrayerSchedule({
    required this.locationLabel,
    required this.timeZoneId,
    required this.days,
    required this.calculatedAt,
  });

  final String locationLabel;
  final String timeZoneId;
  final List<PrayerDay> days;
  final DateTime calculatedAt;

  PrayerDay get today => days.first;

  List<PrayerMoment> get moments => [for (final day in days) ...day.moments];

  /// First prayer strictly after [now]; falls back to the first moment of the
  /// schedule when the clock is somehow ahead of every calculated time.
  PrayerMoment? nextAfter(DateTime now) {
    for (final moment in moments) {
      if (moment.instant.isAfter(now)) return moment;
    }
    return moments.isEmpty ? null : moments.first;
  }

  /// Last prayer at or before [now], used to mark the current window.
  PrayerMoment? currentAt(DateTime now) {
    PrayerMoment? current;
    for (final moment in moments) {
      if (!moment.instant.isAfter(now)) {
        current = moment;
      } else {
        break;
      }
    }
    return current;
  }

  Duration? countdownTo(DateTime now) {
    final next = nextAfter(now);
    if (next == null) return null;
    final remaining = next.instant.difference(now);
    return remaining.isNegative ? Duration.zero : remaining;
  }
}
