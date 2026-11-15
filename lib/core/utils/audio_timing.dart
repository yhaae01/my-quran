import 'dart:math' as math;

/// Estimates the active Arabic word from the audio position.
///
/// Recitation audio has no word timestamps, so the duration is distributed
/// across words in proportion to their length. Longer words receive more time,
/// which tracks recitation rhythm closely enough for reading along without
/// needing an external timing dataset.
int? activeWordIndex({
  required List<String> words,
  required Duration position,
  required Duration duration,
}) {
  if (words.isEmpty || duration <= Duration.zero) return null;
  if (position <= Duration.zero) return null;

  final ratio = (position.inMilliseconds / duration.inMilliseconds).clamp(
    0.0,
    0.999999,
  );

  final weights = [for (final word in words) math.max(1, word.runes.length)];
  final totalWeight = weights.fold<int>(0, (sum, weight) => sum + weight);
  if (totalWeight <= 0) return null;

  var accumulated = 0.0;
  for (var index = 0; index < weights.length; index++) {
    accumulated += weights[index] / totalWeight;
    if (ratio < accumulated) return index;
  }
  return words.length - 1;
}
