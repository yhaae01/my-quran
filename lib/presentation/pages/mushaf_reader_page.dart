import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/app_settings.dart';
import '../../domain/entities/mushaf.dart';
import '../providers/quran_providers.dart';
import '../providers/reading_progress_providers.dart';
import '../providers/settings_providers.dart';
import '../widgets/common_views.dart';
import '../widgets/immersive_reader.dart';
import '../widgets/mushaf_page_widget.dart';
import '../widgets/mushaf_style_sheet.dart';

class MushafReaderPage extends ConsumerStatefulWidget {
  const MushafReaderPage({super.key, this.initialPage = 1});

  final int initialPage;

  @override
  ConsumerState<MushafReaderPage> createState() => _MushafReaderPageState();
}

class _MushafReaderPageState extends ConsumerState<MushafReaderPage> {
  late final PageController _controller;
  late int _currentPage;

  @override
  void initState() {
    super.initState();
    _currentPage = widget.initialPage.clamp(1, mushafPageCount).toInt();
    _controller = PageController(initialPage: _currentPage - 1);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) unawaited(_recordProgress(_currentPage));
    });
  }

  /// Feeds the first verse of the visible page to the reading challenge.
  Future<void> _recordProgress(int pageNumber) async {
    final style = ref.read(
      settingsProvider.select((settings) => settings.mushafStyle),
    );
    try {
      final page = await ref.read(
        mushafPageProvider(MushafPageQuery(style: style, page: pageNumber))
            .future,
      );
      if (page.ayahs.isEmpty) return;
      final ayah = page.ayahs.first;
      var surahName = 'Surah ${ayah.surahNumber}';
      for (final surah in page.surahs) {
        if (surah.number == ayah.surahNumber) {
          surahName = surah.latinName;
          break;
        }
      }
      await ref
          .read(readingProgressProvider.notifier)
          .record(
            surahNumber: ayah.surahNumber,
            ayahNumber: ayah.number,
            surahName: surahName,
          );
    } catch (_) {
      // Progress tracking is best effort; never block page rendering.
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final style = ref.watch(
      settingsProvider.select((settings) => settings.mushafStyle),
    );
    final fontSize = ref.watch(
      settingsProvider.select((settings) => settings.arabicFontSize),
    );
    final fontScale = fontSize / AppSettings.defaultArabicFontSize;

    return ImmersiveReader(
      builder: (context, immersive, toggleImmersive) => Scaffold(
        appBar: immersive
            ? null
            : AppBar(
                title: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Mushaf'),
                    Text(
                      style.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                actions: [
                  IconButton(
                    tooltip: 'Gaya mushaf',
                    onPressed: () => showMushafStyleSheet(context),
                    icon: const Icon(Icons.palette_outlined),
                  ),
                  IconButton(
                    tooltip: 'Buka halaman',
                    onPressed: _showJumpDialog,
                    icon: const Icon(Icons.find_in_page_outlined),
                  ),
                  IconButton(
                    tooltip: 'Mode baca penuh',
                    onPressed: toggleImmersive,
                    icon: const Icon(Icons.fullscreen_rounded),
                  ),
                ],
              ),
        body: Stack(
          children: [
            SafeArea(
              top: immersive,
              bottom: false,
              child: Column(
                children: [
                  Expanded(
                    child: PageView.builder(
                      controller: _controller,
                      itemCount: mushafPageCount,
                      onPageChanged: (index) {
                        setState(() => _currentPage = index + 1);
                        unawaited(_recordProgress(index + 1));
                      },
                      itemBuilder: (context, index) {
                        final query = MushafPageQuery(
                          style: style,
                          page: index + 1,
                        );
                        final pageAsync = ref.watch(mushafPageProvider(query));

                        return pageAsync.when(
                          data: (page) => MushafPageWidget(
                            page: page,
                            fontScale: fontScale,
                          ),
                          loading: () =>
                              const Center(child: CircularProgressIndicator()),
                          error: (error, _) => ErrorView(
                            message: error.toString(),
                            onRetry: () =>
                                ref.invalidate(mushafPageProvider(query)),
                          ),
                        );
                      },
                    ),
                  ),
                  if (!immersive)
                    _PageFooter(
                      currentPage: _currentPage,
                      style: style,
                      onPrevious: _currentPage > 1
                          ? () => _goToPage(_currentPage - 1)
                          : null,
                      onNext: _currentPage < mushafPageCount
                          ? () => _goToPage(_currentPage + 1)
                          : null,
                    ),
                ],
              ),
            ),
            if (immersive)
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Center(
                  child: ImmersivePageBadge(
                    label: '$_currentPage / $mushafPageCount',
                    onPrevious: _currentPage > 1
                        ? () => _goToPage(_currentPage - 1)
                        : null,
                    onNext: _currentPage < mushafPageCount
                        ? () => _goToPage(_currentPage + 1)
                        : null,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _goToPage(int page) {
    final target = page.clamp(1, mushafPageCount).toInt();
    if (target == _currentPage) return;
    _controller.animateToPage(
      target - 1,
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
    );
    setState(() => _currentPage = target);
  }

  Future<void> _showJumpDialog() async {
    final textController = TextEditingController(text: '$_currentPage');
    final page = await showDialog<int>(
      context: context,
      builder: (dialogContext) {
        void submit() {
          final value = int.tryParse(textController.text);
          if (value != null) Navigator.of(dialogContext).pop(value);
        }

        return AlertDialog(
          title: const Text('Buka halaman'),
          content: TextField(
            controller: textController,
            autofocus: true,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Nomor halaman (1-$mushafPageCount)',
            ),
            onSubmitted: (_) => submit(),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Batal'),
            ),
            FilledButton(onPressed: submit, child: const Text('Buka')),
          ],
        );
      },
    );
    textController.dispose();

    if (!mounted || page == null) return;
    _goToPage(page);
  }
}

class _PageFooter extends StatelessWidget {
  const _PageFooter({
    required this.currentPage,
    required this.style,
    this.onPrevious,
    this.onNext,
  });

  final int currentPage;
  final MushafStyle style;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.6),
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Row(
            children: [
              IconButton(
                tooltip: 'Halaman sebelumnya',
                onPressed: onPrevious,
                icon: const Icon(Icons.chevron_left),
              ),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Halaman $currentPage dari $mushafPageCount',
                      style: theme.textTheme.labelLarge,
                    ),
                    Text(
                      style.description,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Halaman berikutnya',
                onPressed: onNext,
                icon: const Icon(Icons.chevron_right),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
