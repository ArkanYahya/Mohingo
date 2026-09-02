import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The resolved [SharedPreferences] instance for this run of the app.
///
/// Overridden in `main()` (and in tests) with an already-awaited instance so
/// every other preference provider can read it synchronously. Only for small,
/// non-critical device/UI settings (theme, colour theme, interface language,
/// text scale, TTS voice/rate/pitch) — never for learner progress data, which
/// lives exclusively in Drift. See docs/TECH_STACK.md.
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError(
    'sharedPreferencesProvider must be overridden in main() with an '
    'awaited SharedPreferences.getInstance() result before runApp().',
  );
});
