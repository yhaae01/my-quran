const List<String> _arabicDigits = [
  '٠',
  '١',
  '٢',
  '٣',
  '٤',
  '٥',
  '٦',
  '٧',
  '٨',
  '٩',
];

/// Converts 255 to ٢٥٥ for ayah/page markers.
String toArabicDigits(int value) {
  final buffer = StringBuffer();
  for (final rune in value.toString().runes) {
    final digit = rune - 0x30;
    if (digit >= 0 && digit <= 9) {
      buffer.write(_arabicDigits[digit]);
    } else {
      buffer.writeCharCode(rune);
    }
  }
  return buffer.toString();
}

/// Some surah descriptions from equran.id contain simple HTML (`<i>`, `<br>`).
String stripHtml(String value) {
  return value
      .replaceAll(RegExp(r'<br\s*/?>', caseSensitive: false), ' ')
      .replaceAll(RegExp(r'<[^>]*>'), '')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
}

const List<String> _indonesianMonths = [
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'Mei',
  'Jun',
  'Jul',
  'Agu',
  'Sep',
  'Okt',
  'Nov',
  'Des',
];

String _twoDigits(int value) => value.toString().padLeft(2, '0');

/// Human-friendly timestamp for saved items, e.g. "Hari ini, 14:05" or
/// "3 Nov 2026, 08:30".
String formatDateTimeLabel(DateTime date) {
  final local = date.toLocal();
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final day = DateTime(local.year, local.month, local.day);
  final time = '${_twoDigits(local.hour)}:${_twoDigits(local.minute)}';

  if (day == today) return 'Hari ini, $time';
  if (today.difference(day).inDays == 1) return 'Kemarin, $time';
  return '${local.day} ${_indonesianMonths[local.month - 1]} '
      '${local.year}, $time';
}
