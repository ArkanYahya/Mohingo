import 'dart:developer' as developer;

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'core/preferences/shared_preferences_provider.dart';
import 'features/account/providers/account_providers.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final sharedPreferences = await SharedPreferences.getInstance();
  final firebaseReady = await _startFirebase();

  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(sharedPreferences),
        firebaseReadyProvider.overrideWithValue(firebaseReady),
      ],
      child: const MohingoApp(),
    ),
  );
}

/// Starts Firebase for accounts and sync. Needs no network. If this build
/// has no Firebase configuration (`lib/firebase_options.dart` is the
/// placeholder until `flutterfire configure` runs — see
/// docs/FIREBASE_SETUP.md) or start-up fails, the app runs local-only:
/// every learning feature works, and Settings offers no sign-in.
Future<bool> _startFirebase() async {
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    return true;
  } on Object catch (e) {
    developer.log(
      'Firebase unavailable, running local-only: $e',
      name: 'mohingo.auth',
    );
    return false;
  }
}
