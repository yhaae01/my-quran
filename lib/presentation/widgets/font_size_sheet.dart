import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/app_settings.dart';
import '../providers/settings_providers.dart';
import 'quran_text.dart';

Future<void> showFontSizeSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    builder: (_) => const FontSizeSheet(),
  );
}

class FontSizeSheet extends ConsumerWidget {
  const FontSizeSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final settings = ref.watch(settingsProvider);
    final style = settings.mushafStyle;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Ukuran teks Arab',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Berlaku untuk tampilan ayat per ayat.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest.withValues(
                  alpha: 0.3,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                basmalahFor(style),
                textAlign: TextAlign.center,
                textDirection: TextDirection.rtl,
                style: TextStyle(
                  fontFamily: style.fontFamily,
                  fontSize: settings.arabicFontSize,
                  height: 1.8,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Text('A', style: theme.textTheme.labelLarge),
                Expanded(
                  child: Slider(
                    value: settings.arabicFontSize,
                    min: AppSettings.minArabicFontSize,
                    max: AppSettings.maxArabicFontSize,
                    divisions:
                        (AppSettings.maxArabicFontSize -
                                AppSettings.minArabicFontSize)
                            .round(),
                    label: '${settings.arabicFontSize.round()} pt',
                    onChanged: (value) => ref
                        .read(settingsProvider.notifier)
                        .setArabicFontSize(value),
                  ),
                ),
                Text(
                  'A',
                  style: theme.textTheme.titleLarge?.copyWith(fontSize: 26),
                ),
              ],
            ),
            Center(
              child: Text(
                '${settings.arabicFontSize.round()} pt',
                style: theme.textTheme.labelLarge?.copyWith(
                  color: theme.colorScheme.primary,
                ),
              ),
            ),
            const SizedBox(height: 14),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Selesai'),
            ),
          ],
        ),
      ),
    );
  }
}
