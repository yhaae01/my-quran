import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/prayer_providers.dart';
import '../widgets/double_back_exit.dart';
import 'bookmarks_page.dart';
import 'dashboard_page.dart';
import 'mushaf_reader_page.dart';
import 'prayer_times_page.dart';
import 'surah_list_page.dart';

class HomeShell extends ConsumerStatefulWidget {
  const HomeShell({super.key});

  @override
  ConsumerState<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends ConsumerState<HomeShell>
    with WidgetsBindingObserver {
  int _selectedIndex = 0;

  late final List<Widget> _pages = [
    DashboardPage(
      onOpenMushaf: () => _selectTab(2),
      onOpenPrayerTimes: () => _selectTab(3),
      onOpenBookmarks: () => _selectTab(4),
    ),
    const SurahListPage(),
    const MushafReaderPage(),
    const PrayerTimesPage(),
    const BookmarksPage(),
  ];

  static const List<NavigationDestination> _destinations = [
    NavigationDestination(
      icon: Icon(Icons.home_outlined),
      selectedIcon: Icon(Icons.home),
      label: 'Beranda',
    ),
    NavigationDestination(
      icon: Icon(Icons.menu_book_outlined),
      selectedIcon: Icon(Icons.menu_book),
      label: 'Surah',
    ),
    NavigationDestination(
      icon: Icon(Icons.auto_stories_outlined),
      selectedIcon: Icon(Icons.auto_stories),
      label: 'Mushaf',
    ),
    NavigationDestination(
      icon: Icon(Icons.mosque_outlined),
      selectedIcon: Icon(Icons.mosque),
      label: 'Shalat',
    ),
    NavigationDestination(
      icon: Icon(Icons.bookmarks_outlined),
      selectedIcon: Icon(Icons.bookmarks),
      label: 'Penanda',
    ),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(prayerSyncProvider.notifier).refresh();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      ref.read(prayerSyncProvider.notifier).refresh(showLoading: false);
    }
  }

  void _selectTab(int index) {
    if (index == _selectedIndex) return;
    setState(() => _selectedIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    // Keeps notifications and the widget updated when settings change.
    ref.watch(prayerSettingsSyncProvider);

    final isLandscape =
        MediaQuery.orientationOf(context) == Orientation.landscape;

    if (!isLandscape) {
      return DoubleBackExit(
        child: Scaffold(
          body: IndexedStack(index: _selectedIndex, children: _pages),
          bottomNavigationBar: NavigationBar(
            selectedIndex: _selectedIndex,
            onDestinationSelected: _selectTab,
            destinations: _destinations,
          ),
        ),
      );
    }

    // Landscape: a slim rail keeps the page area free instead of reserving
    // bottom space that the reader needs.
    return DoubleBackExit(
      child: Scaffold(
        body: Row(
          children: [
            SafeArea(
              right: false,
              child: NavigationRail(
                selectedIndex: _selectedIndex,
                onDestinationSelected: _selectTab,
                labelType: NavigationRailLabelType.none,
                groupAlignment: -0.9,
                backgroundColor: Theme.of(context)
                    .colorScheme
                    .surfaceContainerLow,
                destinations: [
                  for (final destination in _destinations)
                    NavigationRailDestination(
                      icon: destination.icon,
                      selectedIcon: destination.selectedIcon,
                      label: Text(destination.label),
                    ),
                ],
              ),
            ),
            const VerticalDivider(width: 1),
            Expanded(
              child: IndexedStack(index: _selectedIndex, children: _pages),
            ),
          ],
        ),
      ),
    );
  }
}
