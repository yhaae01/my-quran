import 'dart:math' as math;

import 'package:flutter/material.dart';

/// A one-page-at-a-time reader whose pages turn like a leaf of paper lifted off
/// a book.
///
/// Unlike [PageView], the page underneath is not parked off-screen: it lies
/// flat behind the active page, so dragging the active page towards the left
/// peeks at the next page while the leaf folds away. That is the model behind
/// the iBooks-style turn, reached here with a single perspective [Transform]
/// instead of a per-pixel curl, so the GPU only has to composite two layers.
///
/// The leaf only ever rotates about its left edge (the spine), which is why the
/// peek always grows from the right — the direction a mushaf is turned.
class PageFoldPager extends StatefulWidget {
  const PageFoldPager({
    super.key,
    required this.pageCount,
    required this.controller,
    required this.initialPage,
    required this.pageBuilder,
    required this.onPageChanged,
  });

  /// Total number of pages; dragging past either end does nothing.
  final int pageCount;

  /// Lets the owner drive turns from outside, e.g. footer buttons.
  final PageFoldPagerController controller;

  /// Zero-based index of the page shown first.
  final int initialPage;

  /// Builds the page at [index]. Pages are prebuilt by the owner, so this must
  /// stay a cheap lookup — it runs on every frame of a turn.
  final Widget Function(int index) pageBuilder;

  /// Fired once a turn commits, with the zero-based index now shown.
  final ValueChanged<int> onPageChanged;

  @override
  State<PageFoldPager> createState() => _PageFoldPagerState();
}

/// Handle used to turn pages programmatically.
class PageFoldPagerController {
  _PageFoldPagerState? _state;

  void _attach(_PageFoldPagerState state) => _state = state;

  void _detach(_PageFoldPagerState state) {
    if (identical(_state, state)) _state = null;
  }

  /// Zero-based index of the page currently shown, if the pager is mounted.
  int? get page => _state?._page;

  /// Turns the pages between the current one and [index] with the fold
  /// animation. Use [jumpToPage] for targets more than one page away.
  void animateToPage(int index) => _state?._animateTo(index);

  /// Jumps to [index] without animating.
  void jumpToPage(int index) => _state?._jumpTo(index);
}

class _PageFoldPagerState extends State<PageFoldPager>
    with SingleTickerProviderStateMixin {
  /// Turn progress of the leaf in flight: 0 = page resting flat, 1 = fully
  /// turned. Driven either by the drag or by the release animation.
  late final AnimationController _turn;

  late int _page;

  /// +1 while the next page is being revealed, -1 for the previous one.
  int _direction = 1;

  /// Fixed as soon as a drag commits to a direction, so reversing the finger
  /// folds the same leaf back instead of opening a second one.
  bool _directionLocked = false;
  bool _dragging = false;

  /// Signed travel of the current drag, in pixels.
  double _dragDistance = 0;

  @override
  void initState() {
    super.initState();
    _page = widget.initialPage.clamp(0, widget.pageCount - 1);
    _turn = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    )..addStatusListener(_onTurnStatus);
    widget.controller._attach(this);
  }

  @override
  void dispose() {
    widget.controller._detach(this);
    _turn.dispose();
    super.dispose();
  }

  void _onTurnStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed && !_dragging) _commit();
  }

  /// Applies a finished turn: the leaf is out of the way (or has covered the
  /// page), so the neighbour becomes the visible page.
  void _commit() {
    final target = _page + _direction;
    if (target < 0 || target >= widget.pageCount) {
      _turn.value = 0;
      return;
    }
    setState(() => _page = target);
    _turn.value = 0;
    widget.onPageChanged(_page);
  }

  void _animateTo(int index) {
    final target = index.clamp(0, widget.pageCount - 1);
    if (target == _page) return;
    _turn.stop();
    _dragging = false;
    _dragDistance = 0;
    _direction = target > _page ? 1 : -1;
    _directionLocked = true;
    _turn.value = 0;
    _turn.animateTo(
      1,
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeInOutCubic,
    );
  }

  void _jumpTo(int index) {
    final target = index.clamp(0, widget.pageCount - 1);
    if (target == _page) return;
    _turn.stop();
    _turn.value = 0;
    setState(() => _page = target);
    widget.onPageChanged(_page);
  }

  void _onDragStart(DragStartDetails details) {
    _turn.stop();
    _turn.value = 0;
    _dragging = true;
    _dragDistance = 0;
    _directionLocked = false;
  }

  void _onDragUpdate(DragUpdateDetails details, double width) {
    if (!_dragging) return;

    if (!_directionLocked) {
      final dx = details.delta.dx;
      if (dx == 0) return;
      final forward = dx < 0;
      final canTurn = forward ? _page < widget.pageCount - 1 : _page > 0;
      // Leave the direction unlocked at the ends so reversing the pull starts
      // a turn the other way instead of gripping a page that cannot move.
      if (!canTurn) return;
      _direction = forward ? 1 : -1;
      _directionLocked = true;
    }

    _dragDistance += details.delta.dx;
    // Only travel in the locked direction opens the fold, so pulling back folds
    // the same leaf shut again.
    final progress = (-_dragDistance * _direction) / (width * 0.85);
    _turn.value = progress.clamp(0.0, 1.0);
  }

  void _onDragEnd(DragEndDetails details) {
    if (!_dragging) return;
    _dragging = false;
    if (!_directionLocked) return;
    _directionLocked = false;

    final progress = _turn.value;
    if (progress <= 0) return;

    // A quick flick in the turn direction counts even if the drag was short,
    // but never a twitch.
    final flick = -details.velocity.pixelsPerSecond.dx * _direction;
    final commit = progress > 0.35 || (progress > 0.1 && flick > 600);

    if (!commit) {
      _settleBack(progress);
      return;
    }
    _turn.animateTo(
      1,
      duration: Duration(
        milliseconds: (240 * (1 - progress)).round().clamp(90, 240),
      ),
      curve: Curves.easeOutCubic,
    );
  }

  void _onDragCancel() {
    if (!_dragging) return;
    _dragging = false;
    _directionLocked = false;
    _settleBack(_turn.value);
  }

  /// Folds the leaf shut again, shorter for one that barely opened.
  ///
  /// This deliberately uses [AnimationController.animateBack]: animating
  /// towards zero with `animateTo` still reports a *completed* animation, which
  /// would be mistaken for a committed turn.
  void _settleBack(double progress) {
    if (progress <= 0) return;
    _turn.animateBack(
      0,
      duration: Duration(milliseconds: (220 * progress).round().clamp(80, 220)),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;

        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          // Swiping left brings the next page, matching the mushaf order.
          onHorizontalDragStart: _onDragStart,
          onHorizontalDragUpdate: (details) => _onDragUpdate(details, width),
          onHorizontalDragEnd: _onDragEnd,
          onHorizontalDragCancel: _onDragCancel,
          child: AnimatedBuilder(
            animation: _turn,
            builder: (context, _) {
              final progress = _turn.value;
              final forward = _direction > 0;

              // Going forward the next page waits underneath and the current
              // page peels off it; going back the previous page folds in over
              // the page being left behind.
              final baseIndex = forward
                  ? math.min(_page + 1, widget.pageCount - 1)
                  : _page;
              final leafIndex = forward
                  ? _page
                  : math.max(_page - 1, 0);

              return Stack(
                fit: StackFit.expand,
                children: [
                  widget.pageBuilder(baseIndex),
                  _buildLeaf(leafIndex, progress, forward, width),
                ],
              );
            },
          ),
        );
      },
    );
  }

  /// The turning leaf: hinged on the left edge with a little perspective, a
  /// slight drift towards the spine, and shading that deepens as it lifts.
  Widget _buildLeaf(
    int index,
    double progress,
    bool forward,
    double width,
  ) {
    // Forward: 0 → -90°, the free edge swinging away from the reader.
    // Backward: -90° → 0, the previous leaf dropping back into place.
    final angle = (forward ? -progress : progress - 1) * math.pi / 2;
    final slide = (forward ? -progress : progress - 1) * width * 0.1;
    final shade = forward ? progress : 1 - progress;

    return Transform.translate(
      offset: Offset(slide, 0),
      child: Transform(
        alignment: Alignment.centerLeft,
        transform: Matrix4.identity()
          ..setEntry(3, 2, 0.0015)
          ..rotateY(angle),
        child: Stack(
          fit: StackFit.expand,
          children: [
            widget.pageBuilder(index),
            IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.centerRight,
                    end: Alignment.centerLeft,
                    // Shade the free edge a touch and the spine a little more,
                    // which reads as paper bending away from the light.
                    colors: [
                      Colors.black.withValues(alpha: 0.2 * shade),
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.32 * shade),
                    ],
                    stops: const [0, 0.55, 1],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
