import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mohingo/content/audio/speakable_strings.dart';
import 'package:mohingo/features/speech/domain/audio_clip_index.dart';
import 'package:path/path.dart' as p;

import 'level_gate_config.dart';

/// A released level ships a clip for every string the app speaks (ADR 0008).
///
/// The manifest is what `tool/audio/generate_audio.py` wrote; the list of
/// strings is what the app's call sites ask for. When the two drift — a
/// bundle edit without a regeneration, a new call site, a stray file — one
/// of these says which and how to fix it.
void main() {
  for (final gate in kLevelGates) {
    group(gate.levelId.toUpperCase(), () {
      final manifestFile = File(gate.audioManifestAssetPath);
      final dir = p.dirname(gate.audioManifestAssetPath);
      final regenerate =
          'regenerate with: python tool/audio/generate_audio.py '
          '--level ${gate.levelId.toUpperCase()} --prune';

      AudioManifest manifest() => AudioManifest.parse(
        manifestFile.readAsStringSync(),
        assetDirectory: dir,
      );

      List<String> clipFilesOnDisk() => [
        for (final f in Directory(p.join(dir, 'clips')).listSync())
          if (f is File && f.path.endsWith('.m4a'))
            p.join(dir, 'clips', p.basename(f.path)).replaceAll(r'\', '/'),
      ];

      test('ships a manifest generated for its contentVersion', () {
        expect(
          manifestFile.existsSync(),
          isTrue,
          reason: '${gate.audioManifestAssetPath} is missing; $regenerate',
        );
        final m = manifest();
        expect(m.levelId, gate.levelId);
        expect(
          m.contentVersion,
          gate.bundle().contentVersion,
          reason:
              'the bundle changed since its audio was generated; $regenerate',
        );
      });

      test(
        'has a clip for every speakable string in the role the app asks for',
        () {
          final m = manifest();
          final missing = <String>[];
          for (final s in speakableStringsOf(gate.bundle())) {
            final roles = m.clips[textKeyFor(s.text)];
            if (roles == null || !roles.containsKey(s.role)) {
              missing.add('${s.source} [${s.role}]: ${s.text}');
            }
          }
          expect(
            missing,
            isEmpty,
            reason:
                '${missing.length} spoken strings have no clip; $regenerate\n'
                '${missing.take(20).join('\n')}',
          );
        },
      );

      test('every referenced clip exists and every clip is referenced', () {
        final referenced = {
          for (final roles in manifest().clips.values) ...roles.values,
        };
        for (final path in referenced) {
          expect(File(path).existsSync(), isTrue, reason: '$path; $regenerate');
        }
        final orphans = clipFilesOnDisk().toSet().difference(referenced);
        expect(
          orphans,
          isEmpty,
          reason:
              '${orphans.length} clip files nothing references; $regenerate',
        );
      });

      test('stays within its audio budget', () {
        final bytes = clipFilesOnDisk().fold<int>(
          0,
          (n, path) => n + File(path).lengthSync(),
        );
        expect(
          bytes,
          lessThanOrEqualTo(gate.audioBudgetBytes),
          reason:
              '$bytes bytes of clips against a budget of '
              '${gate.audioBudgetBytes}; see docs/LEVEL_STANDARD.md',
        );
      });
    });
  }
}
