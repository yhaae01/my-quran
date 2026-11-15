import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:home_widget/home_widget.dart';

import 'prayer_widget_data_source.dart';

/// Entry point used by the Android widget's refresh action.
///
/// home_widget runs this in a background isolate, so it must be a top-level
/// function annotated with `@pragma('vm:entry-point')` and it must not rely on
/// the running app's ProviderScope or Hive boxes. The last schedule parameters
/// travel inside the widget payload itself, which lets the callback recompute
/// the prayer times offline and repaint the widget without opening the app.
@pragma('vm:entry-point')
Future<void> prayerWidgetBackgroundCallback(Uri? uri) async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await PrayerWidgetDataSource().refreshFromStoredData();
  } catch (error, stackTrace) {
    debugPrint('Pembaruan widget latar belakang gagal: $error\n$stackTrace');
    // Keep the native fallback visible instead of leaving a blank widget.
    try {
      await PrayerWidgetDataSource().writeFallbackPayload();
    } catch (_) {
      // The native provider already renders placeholders for missing data.
    }
  }
}

/// Registers [prayerWidgetBackgroundCallback] with home_widget.
///
/// Registration is Android-only because widget interactivity uses a Headless
/// Flutter engine there; iOS widgets use a WidgetKit timeline instead.
Future<void> registerPrayerWidgetBackgroundCallback() async {
  if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return;
  try {
    await HomeWidget.registerInteractivityCallback(
      prayerWidgetBackgroundCallback,
    );
  } catch (error) {
    debugPrint('Callback latar belakang widget tidak terdaftar: $error');
  }
}
