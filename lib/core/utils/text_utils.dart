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

String formatShortDate(DateTime date) {
  final local = date.toLocal();
  return '${local.day} ${_indonesianMonths[local.month - 1]} ${local.year}';
}
