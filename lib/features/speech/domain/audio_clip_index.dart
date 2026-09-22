import 'dart:convert';

import 'package:crypto/crypto.dart';

/// The role a clip was rendered for when the text has no speaker: the
/// teacher voice reads vocabulary, grammar, key phrases and transcripts.
const kTeacherRole = '_';

/// The `speaker` a caller passes for the other person in a speaking task.
const kPartnerSpeaker = 'partner';

/// The one text rule shared with `tool/audio/mohingo_audio/textkey.py`:
/// curly apostrophe to straight, whitespace runs to one space, trimmed.
/// No Unicode normalisation — the tool refuses non-NFC text instead, since
/// Dart has no normaliser and both sides must agree byte for byte.
String normaliseSpeechText(String text) =>
    text.replaceAll('’', "'").replaceAll(RegExp(r'\s+'), ' ').trim();

/// The manifest key for [text]: the first 16 hex digits of its SHA-1.
String textKeyFor(String text) => sha1
    .convert(utf8.encode(normaliseSpeechText(text)))
    .toString()
    .substring(0, 16);

/// One level's `manifest.json` (schema in docs/DATA_MODEL.md), with clip
/// paths already resolved to full asset paths.
class AudioManifest {
  const AudioManifest({
    required this.levelId,
    required this.contentVersion,
    required this.clips,
  });

  /// Parses [json]; [assetDirectory] is the manifest's own directory (e.g.
  /// `assets/audio/en/A1`), which its relative clip paths resolve against.
  /// Throws [FormatException] for anything that is not a manifest.
  factory AudioManifest.parse(String json, {required String assetDirectory}) {
    final Object? decoded;
    try {
      decoded = jsonDecode(json);
    } on FormatException {
      rethrow;
    }
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('audio manifest is not an object');
    }
    final rawClips = decoded['clips'];
    if (rawClips is! Map<String, dynamic>) {
      throw const FormatException('audio manifest has no clips map');
    }
    final clips = <String, Map<String, String>>{};
    rawClips.forEach((key, roles) {
      if (roles is! Map<String, dynamic>) {
        throw FormatException('clip entry $key is not a role map');
      }
      clips[key] = {
        for (final e in roles.entries)
          if (e.value is String) e.key: '$assetDirectory/${e.value as String}',
      };
    });
    return AudioManifest(
      levelId: decoded['levelId'] as String? ?? '',
      contentVersion: decoded['contentVersion'] as String? ?? '',
      clips: clips,
    );
  }

  final String levelId;
  final String contentVersion;

  /// textKey → role → asset path.
  final Map<String, Map<String, String>> clips;
}

/// Every bundled clip the app knows about, across all released levels.
class AudioClipIndex {
  const AudioClipIndex.empty() : _clips = const {};

  factory AudioClipIndex.fromManifests(Iterable<AudioManifest> manifests) {
    final merged = <String, Map<String, String>>{};
    for (final m in manifests) {
      m.clips.forEach((key, roles) {
        merged.putIfAbsent(key, () => {}).addAll(roles);
      });
    }
    return AudioClipIndex._(merged);
  }

  const AudioClipIndex._(this._clips);

  final Map<String, Map<String, String>> _clips;

  int get clipCount =>
      _clips.values.fold(0, (n, roles) => n + roles.length);

  /// The clip for [text] in [speaker]'s voice, else the teacher's, else any
  /// voice at all — a clip in the wrong voice beats the device engine.
  String? assetPathFor(String text, {String? speaker}) {
    final roles = _clips[textKeyFor(text)];
    if (roles == null || roles.isEmpty) return null;
    return roles[speaker ?? kTeacherRole] ??
        roles[kTeacherRole] ??
        roles.values.first;
  }
}
