import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Requires two back presses within [window] to leave the app.
///
/// The first press only shows a short hint, so a stray back gesture does not
/// close the reader. This wraps the root shell; nested routes above it keep
/// their normal back behaviour because the system pops them first.
class DoubleBackExit extends StatefulWidget {
  const DoubleBackExit({
    super.key,
    required this.child,
    this.window = const Duration(seconds: 2),
    this.message = 'Tekan sekali lagi untuk keluar aplikasi',
  });

  final Widget child;
  final Duration window;
  final String message;

  @override
  State<DoubleBackExit> createState() => _DoubleBackExitState();
}

class _DoubleBackExitState extends State<DoubleBackExit> {
  DateTime? _lastPress;

  void _handleBack() {
    final now = DateTime.now();
    final last = _lastPress;
    if (last != null && now.difference(last) <= widget.window) {
      unawaited(SystemNavigator.pop());
      return;
    }

    _lastPress = now;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(widget.message), duration: widget.window),
      );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        _handleBack();
      },
      child: widget.child,
    );
  }
}
