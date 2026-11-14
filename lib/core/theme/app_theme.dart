import 'package:flutter/material.dart';

import '../../domain/entities/bookmark.dart';

abstract final class AppColors {
  static const Color emerald = Color(0xFF0F5B4E);
  static const Color gold = Color(0xFFC9A227);
  static const Color parchment = Color(0xFFFFFBF1);
  static const Color parchmentDark = Color(0xFF16201C);
  static const Color bookmarkRed = Color(0xFFD9534F);
  static const Color bookmarkGreen = Color(0xFF3E9D6E);
  static const Color bookmarkYellow = Color(0xFFE6B422);
  static const Color bookmarkBlue = Color(0xFF3D7EDB);
}

extension BookmarkColorPalette on BookmarkColor {
  Color get color => switch (this) {
    BookmarkColor.red => AppColors.bookmarkRed,
    BookmarkColor.green => AppColors.bookmarkGreen,
    BookmarkColor.yellow => AppColors.bookmarkYellow,
    BookmarkColor.blue => AppColors.bookmarkBlue,
  };

  Color get onColor =>
      this == BookmarkColor.yellow ? Colors.black87 : Colors.white;
}

abstract final class AppTheme {
  static ThemeData light() => _build(Brightness.light);

  static ThemeData dark() => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final scheme =
        ColorScheme.fromSeed(
          seedColor: AppColors.emerald,
          brightness: brightness,
        ).copyWith(
          secondary: AppColors.gold,
          surface: isDark ? AppColors.parchmentDark : AppColors.parchment,
        );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: scheme.surface,
      appBarTheme: AppBarTheme(
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
        elevation: 0,
        scrolledUnderElevation: 1,
        surfaceTintColor: scheme.surfaceTint,
        centerTitle: false,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: scheme.surfaceContainerLow,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.6)),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: scheme.outlineVariant.withValues(alpha: 0.6),
        thickness: 1,
        space: 1,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: scheme.surfaceContainerLow,
        indicatorColor: scheme.secondaryContainer,
        elevation: 2,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: scheme.surface,
        showDragHandle: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surfaceContainerHighest.withValues(alpha: 0.35),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
