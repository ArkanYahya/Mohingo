import 'dart:async';

import 'package:permission_handler/permission_handler.dart' as ph;
import 'package:speech_to_text/speech_to_text.dart' as stt;

import '../domain/speech_recognition_service.dart';

/// Wraps `package:speech_to_text` for recognition and
/// `package:permission_handler` for microphone permission — kept as two
/// separate packages deliberately: `permission_handler`'s `.status` getter
/// can check current permission *without* prompting (needed for Settings'
/// "microphone permission status" display and for deciding, before showing
/// a `speak` activity, whether to offer the microphone at all), which
/// `speech_to_text.initialize()` alone doesn't cleanly separate from
/// requesting it.
///
/// API verified directly against the installed speech_to_text 7.4.0 source
/// this session (`SpeechListenOptions`, the async `initialize`/`listen`
/// shape, `SpeechRecognitionResult.recognizedWords`/`.finalResult`).
///
/// **Not verified on a real device** — no Android/iOS device or emulator is
/// available in this dev environment (see docs/TESTING.md). Needs manual
/// verification on a real device before shipping, especially around
/// [isAvailableForLocale]'s first-call behaviour (see its doc comment).
class DeviceSpeechRecognitionService implements SpeechRecognitionService {
  DeviceSpeechRecognitionService({stt.SpeechToText? speechToText})
    : _speech = speechToText ?? stt.SpeechToText();

  final stt.SpeechToText _speech;
  bool _initialized = false;

  Future<bool> _ensureInitialized() async {
    if (_initialized) return true;
    _initialized = await _speech.initialize();
    return _initialized;
  }

  @override
  Future<bool> isAvailableForLocale(String localeCode) async {
    // `speech_to_text.initialize()` may itself trigger the OS permission
    // prompt on first call on some platforms — callers must only reach this
    // after a deliberate learner action (tapping "record"), never
    // speculatively on screen load. See docs/ARCHITECTURE.md.
    if (!await _ensureInitialized()) return false;
    final locales = await _speech.locales();
    final languagePrefix = localeCode.toLowerCase().split(RegExp('[-_]')).first;
    return locales.any(
      (locale) => locale.localeId.toLowerCase().startsWith(languagePrefix),
    );
  }

  @override
  Future<SpeechPermissionStatus> permissionStatus() async {
    return _mapStatus(await ph.Permission.microphone.status);
  }

  @override
  Future<SpeechPermissionStatus> requestPermission() async {
    return _mapStatus(await ph.Permission.microphone.request());
  }

  SpeechPermissionStatus _mapStatus(ph.PermissionStatus status) {
    if (status.isGranted) return SpeechPermissionStatus.granted;
    if (status.isPermanentlyDenied) {
      return SpeechPermissionStatus.permanentlyDenied;
    }
    if (status.isDenied) return SpeechPermissionStatus.denied;
    return SpeechPermissionStatus.notDetermined;
  }

  @override
  Stream<SpeechRecognitionResult> recognize({
    required String localeCode,
    Duration? listenFor,
  }) {
    late final StreamController<SpeechRecognitionResult> controller;
    controller = StreamController<SpeechRecognitionResult>(
      onListen: () async {
        try {
          final ready = await _ensureInitialized();
          if (!ready) {
            await controller.close();
            return;
          }
          await _speech.listen(
            onResult: (result) {
              controller.add(
                SpeechRecognitionResult(
                  transcript: result.recognizedWords,
                  isFinal: result.finalResult,
                ),
              );
              if (result.finalResult) controller.close();
            },
            listenOptions: stt.SpeechListenOptions(
              localeId: localeCode,
              partialResults: true,
              listenFor: listenFor,
              cancelOnError: true,
            ),
          );
        } catch (error, stackTrace) {
          controller.addError(error, stackTrace);
          await controller.close();
        }
      },
      onCancel: () => _speech.cancel(),
    );
    return controller.stream;
  }

  @override
  Future<void> cancel() => _speech.cancel();
}
