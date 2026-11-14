import 'package:flutter/material.dart';

/// Distraction-free reading chrome.
///
/// The reader decides what to hide; this widget only tracks the mode. It turns
/// on automatically in landscape (where the app bars take precious vertical
/// space) and can be toggled from the reader app bar in portrait.
class ImmersiveReader extends StatefulWidget {
  const ImmersiveReader({super.key, required this.builder});

  /// Builds the reader, receiving whether the chrome is hidden and a callback
  /// that flips it.
  final Widget Function(
    BuildContext context,
    bool immersive,
    VoidCallback toggle,
  )
  builder;

  @override
  State<ImmersiveReader> createState() => _ImmersiveReaderState();
}

class _ImmersiveReaderState extends State<ImmersiveReader> {
  bool _immersive = false;
  Orientation? _orientation;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final orientation = MediaQuery.orientationOf(context);
    if (orientation == _orientation) return;
    _orientation = orientation;
    // A rotation resets any manual choice: landscape is immersive by default,
    // portrait returns to the full reader chrome.
    _immersive = orientation == Orientation.landscape;
  }

  void _toggle() => setState(() => _immersive = !_immersive);

  @override
  Widget build(BuildContext context) {
    final reader = widget.builder(context, _immersive, _toggle);
    if (!_immersive) return reader;

    return Stack(
      children: [
        reader,
        Positioned(
          top: 0,
          right: 0,
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: _ImmersiveExitButton(onPressed: _toggle),
            ),
          ),
        ),
      ],
    );
  }
}

class _ImmersiveExitButton extends StatelessWidget {
  const _ImmersiveExitButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: scheme.surfaceContainerHigh.withValues(alpha: 0.92),
      elevation: 2,
      shape: const CircleBorder(),
      child: IconButton(
        tooltip: 'Tampilkan kontrol baca',
        onPressed: onPressed,
        icon: Icon(Icons.fullscreen_exit_rounded, color: scheme.onSurface),
      ),
    );
  }
}

/// Small floating page indicator used when the mushaf footer is hidden.
class ImmersivePageBadge extends StatelessWidget {
  const ImmersivePageBadge({
    super.key,
    required this.label,
    this.onPrevious,
    this.onNext,
  });

  final String label;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Material(
          color: theme.colorScheme.surfaceContainerHigh.withValues(alpha: 0.94),
          elevation: 2,
          borderRadius: BorderRadius.circular(24),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                tooltip: 'Sebelumnya',
                onPressed: onPrevious,
                visualDensity: VisualDensity.compact,
                icon: const Icon(Icons.chevron_left),
              ),
              Text(label, style: theme.textTheme.labelMedium),
              IconButton(
                tooltip: 'Berikutnya',
                onPressed: onNext,
                visualDensity: VisualDensity.compact,
                icon: const Icon(Icons.chevron_right),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
