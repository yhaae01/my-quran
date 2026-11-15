import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../domain/entities/bookmark.dart';

/// A small ribbon emblem that replaces the plain coloured dots used by the
/// bookmark screens.
///
/// It keeps the four category colours, but presents them as a minimalist
/// suspended bookmark with a gradient, soft shadow and a check mark when
/// selected. The same widget scales from filter chips down to inline tags.
class BookmarkBadge extends StatelessWidget {
  const BookmarkBadge({
    super.key,
    required this.color,
    this.size = 22,
    this.selected = false,
    this.showShadow = true,
  });

  final BookmarkColor color;

  /// Width of the ribbon. Height is derived so the proportions stay fixed.
  final double size;

  /// Draws a white check mark over the ribbon, used by the colour picker.
  final bool selected;

  final bool showShadow;

  @override
  Widget build(BuildContext context) {
    final height = size * 1.22;
    final base = color.color;

    return Semantics(
      label: 'Penanda ${color.label.toLowerCase()}',
      child: SizedBox(
        width: size,
        height: height,
        child: PhysicalShape(
          clipper: const _RibbonClipper(),
          color: base,
          elevation: showShadow ? 2.5 : 0,
          shadowColor: base.withValues(alpha: 0.45),
          clipBehavior: Clip.antiAlias,
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color.lerp(base, Colors.white, 0.28)!,
                  base,
                  Color.lerp(base, Colors.black, 0.18)!,
                ],
                stops: const [0, 0.55, 1],
              ),
            ),
            child: Center(
              child: selected
                  ? Icon(
                      Icons.check_rounded,
                      size: size * 0.56,
                      color: color.onColor,
                    )
                  : size >= 30
                  ? Icon(
                      Icons.bookmark_rounded,
                      size: size * 0.5,
                      color: Colors.white.withValues(alpha: 0.92),
                    )
                  : null,
            ),
          ),
        ),
      ),
    );
  }
}

/// Classic bookmark silhouette: rounded shoulders and a V-shaped tail.
class _RibbonClipper extends CustomClipper<Path> {
  const _RibbonClipper();

  @override
  Path getClip(Size size) {
    final width = size.width;
    final height = size.height;
    final radius = width * 0.24;
    final notch = height * 0.17;

    return Path()
      ..moveTo(radius, 0)
      ..lineTo(width - radius, 0)
      ..quadraticBezierTo(width, 0, width, radius)
      ..lineTo(width, height)
      ..lineTo(width / 2, height - notch)
      ..lineTo(0, height)
      ..lineTo(0, radius)
      ..quadraticBezierTo(0, 0, radius, 0)
      ..close();
  }

  @override
  bool shouldReclip(_RibbonClipper oldClipper) => false;
}
