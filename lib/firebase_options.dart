// Placeholder until the project is connected to Firebase.
//
// `flutterfire configure` (docs/FIREBASE_SETUP.md) overwrites this file
// with the real, generated options. Until then the app starts local-only:
// `main` catches the error below and offers no sign-in.
// ignore_for_file: type=lint
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    throw UnsupportedError(
      'Firebase is not configured for this build yet — run '
      '`flutterfire configure` (see docs/FIREBASE_SETUP.md).',
    );
  }
}
