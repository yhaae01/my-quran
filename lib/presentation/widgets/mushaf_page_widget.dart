import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/text_utils.dart';
import '../../domain/entities/ayah.dart';
import '../../domain/entities/bookmark.dart';
import '../../domain/entities/mushaf.dart';
import '../../domain/entities/surah.dart';
import '../providers/bookmark_providers.dart';
import 'bookmark_sheet.dart';
import 'quran_text.dart';

class MushafPageWidget extends StatelessWidget {
  const MushafPageWidget({super.key, required this.page, this.fontScale = 1});

  final MushafPage page;

  /// Multiplies the layout-derived Arabic size so the reading preferences
  /// slider also resizes the page-by-page mushaf.
  final double fontScale;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final palette = isDark ? _MushafPalette.dark : _MushafPalette.light;

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final fontSize = (constraints.maxWidth * 0.055 * fontScale).clamp(
            15.0,
            40.0,
          );

          return DecoratedBox(
            decoration: BoxDecoration(
              color: palette.background,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: palette.accent.withValues(alpha: 0.55),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.08),
                  blurRadius: 18,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Container(
              margin: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: palette.accent.withValues(alpha: 0.35),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
                child: Column(
                  children: [
                    _PageHeader(page: page, palette: palette),
                    const SizedBox(height: 8),
                    Container(
                      height: 1,
                      color: palette.accent.withValues(alpha: 0.3),
                    ),
                    const SizedBox(height: 10),
                    Expanded(
                      child: SingleChildScrollView(
                        child: _PageContent(
                          page: page,
                          palette: palette,
                          fontSize: fontSize,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    _PageFooter(page: page, palette: palette),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _PageHeader extends StatelessWidget {
  const _PageHeader({required this.page, required this.palette});

  final MushafPage page;
  final _MushafPalette palette;

  @override
  Widget build(BuildContext context) {
    final names = page.surahs.map((surah) => surah.name).toSet().join(' • ');

    return Row(
      children: [
        Text(
          'Juz ${page.juz}',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: palette.ink.withValues(alpha: 0.65),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            names.isEmpty ? 'Al-Qur\'an' : names,
            textAlign: TextAlign.center,
            textDirection: TextDirection.rtl,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontFamily: page.style.fontFamily,
              fontSize: 17,
              height: 1.4,
              color: palette.ink.withValues(alpha: 0.85),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          'Hal. ${page.number}',
          style: TextStyle(
            fontSize: 11,
            color: palette.ink.withValues(alpha: 0.65),
          ),
        ),
      ],
    );
  }
}

class _PageContent extends StatelessWidget {
  const _PageContent({
    required this.page,
    required this.palette,
    required this.fontSize,
  });

  final MushafPage page;
  final _MushafPalette palette;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    if (page.ayahs.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Text(
          'Tidak ada ayat pada halaman ini.',
          textAlign: TextAlign.center,
          style: TextStyle(color: palette.ink.withValues(alpha: 0.7)),
        ),
      );
    }

    final surahByNumber = <int, Surah>{
      for (final surah in page.surahs) surah.number: surah,
    };
    final groups = <int, List<Ayah>>{};
    for (final ayah in page.ayahs) {
      groups.putIfAbsent(ayah.surahNumber, () => []).add(ayah);
    }

    final children = <Widget>[];
    for (final entry in groups.entries) {
      final surah = surahByNumber[entry.key];
      final startsSurah = entry.value.first.number == 1;

      if (startsSurah && surah != null) {
        children.add(
          _SurahHeading(
            surah: surah,
            style: page.style,
            palette: palette,
            fontSize: fontSize,
          ),
        );
        if (surah.number != 1 && surah.number != 9) {
          children.add(
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                basmalahFor(page.style),
                textAlign: TextAlign.center,
                textDirection: TextDirection.rtl,
                style: TextStyle(
                  fontFamily: page.style.fontFamily,
                  fontSize: fontSize * 0.95,
                  height: 1.8,
                  color: palette.ink.withValues(alpha: 0.85),
                ),
              ),
            ),
          );
        }
      }

      children.add(
        _AyahFlow(
          ayahs: entry.value,
          surah: surah,
          style: page.style,
          palette: palette,
          fontSize: fontSize,
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: children,
    );
  }
}

class _SurahHeading extends StatelessWidget {
  const _SurahHeading({
    required this.surah,
    required this.style,
    required this.palette,
    required this.fontSize,
  });

  final Surah surah;
  final MushafStyle style;
  final _MushafPalette palette;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 2, bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: palette.accent.withValues(alpha: 0.07),
        border: Border.symmetric(
          horizontal: BorderSide(color: palette.accent.withValues(alpha: 0.45)),
        ),
      ),
      child: Text(
        'سُورَةُ ${surah.name}',
        textAlign: TextAlign.center,
        textDirection: TextDirection.rtl,
        style: TextStyle(
          fontFamily: style.fontFamily,
          fontSize: fontSize * 1.05,
          height: 1.5,
          color: palette.ink,
        ),
      ),
    );
  }
}

/// Flowing text of one surah's verses on the page.
///
/// Every verse is its own tappable [TextSpan] so the reader can tap an ayah
/// directly, without leaving the mushaf, to open its bookmark action sheet.
/// The saved verse gets a soft tinted background.
class _AyahFlow extends ConsumerStatefulWidget {
  const _AyahFlow({
    required this.ayahs,
    required this.surah,
    required this.style,
    required this.palette,
    required this.fontSize,
  });

  final List<Ayah> ayahs;
  final Surah? surah;
  final MushafStyle style;
  final _MushafPalette palette;
  final double fontSize;

  @override
  ConsumerState<_AyahFlow> createState() => _AyahFlowState();
}

class _AyahFlowState extends ConsumerState<_AyahFlow> {
  final Map<int, TapGestureRecognizer> _recognizers = {};

  TapGestureRecognizer _recognizerFor(Ayah ayah) {
    return _recognizers.putIfAbsent(ayah.number, () {
      return TapGestureRecognizer()..onTap = () => _openActions(ayah);
    });
  }

  void _openActions(Ayah ayah) {
    final surah = widget.surah;
    if (surah == null) return;

    final existing = ref.read(
      bookmarkAtProvider((surah: ayah.surahNumber, verse: ayah.number)),
    );
    showBookmarkSheet(
      context,
      surah: surah,
      ayah: ayah,
      existing: existing,
      style: widget.style,
    );
  }

  @override
  void dispose() {
    for (final recognizer in _recognizers.values) {
      recognizer.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bookmarks = ref.watch(bookmarksProvider).value ?? const <Bookmark>[];
    final savedVerses = <int>{
      for (final bookmark in bookmarks)
        if (widget.ayahs.isNotEmpty &&
            bookmark.surahNumber == widget.ayahs.first.surahNumber)
          bookmark.verseNumber,
    };

    final spans = <InlineSpan>[];
    for (final ayah in widget.ayahs) {
      final isSaved = savedVerses.contains(ayah.number);
      spans.add(
        TextSpan(
          text: '${ayah.arabicFor(widget.style)}\u00A0',
          recognizer: _recognizerFor(ayah),
          mouseCursor: SystemMouseCursors.click,
          style: isSaved
              ? TextStyle(
                  backgroundColor: widget.palette.accent.withValues(
                    alpha: 0.16,
                  ),
                )
              : null,
        ),
      );
      spans.add(
        TextSpan(
          text: '﴿${toArabicDigits(ayah.number)}﴾ ',
          recognizer: _recognizerFor(ayah),
          mouseCursor: SystemMouseCursors.click,
          style: TextStyle(
            fontSize: widget.fontSize * 0.72,
            color: widget.palette.accent,
          ),
        ),
      );
    }

    return Padding(
      padding: EdgeInsets.only(bottom: widget.fontSize * 0.45),
      child: Text.rich(
        TextSpan(children: spans),
        textDirection: TextDirection.rtl,
        textAlign: TextAlign.justify,
        style: TextStyle(
          fontFamily: widget.style.fontFamily,
          fontSize: widget.fontSize,
          height: 2,
          color: widget.palette.ink,
        ),
      ),
    );
  }
}

class _PageFooter extends StatelessWidget {
  const _PageFooter({required this.page, required this.palette});

  final MushafPage page;
  final _MushafPalette palette;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Halaman ${page.number} mushaf ${page.style.label}',
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 1,
              color: palette.accent.withValues(alpha: 0.3),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              '﴿${toArabicDigits(page.number)}﴾',
              textDirection: TextDirection.rtl,
              style: TextStyle(
                fontFamily: page.style.fontFamily,
                fontSize: 16,
                height: 1.4,
                color: palette.accent,
              ),
            ),
          ),
          Expanded(
            child: Container(
              height: 1,
              color: palette.accent.withValues(alpha: 0.3),
            ),
          ),
        ],
      ),
    );
  }
}

class _MushafPalette {
  const _MushafPalette({
    required this.background,
    required this.ink,
    required this.accent,
  });

  final Color background;
  final Color ink;
  final Color accent;

  static const _MushafPalette light = _MushafPalette(
    background: Color(0xFFFFFCF3),
    ink: Color(0xFF1E2A24),
    accent: Color(0xFF9A7B1F),
  );

  static const _MushafPalette dark = _MushafPalette(
    background: Color(0xFF1B2621),
    ink: Color(0xFFEDE7D8),
    accent: AppColors.gold,
  );
}
