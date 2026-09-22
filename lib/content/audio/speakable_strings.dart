import '../../features/speech/domain/audio_clip_index.dart';
import '../models/activity.dart';
import '../models/course_bundle.dart';

/// One string the app hands to `TextToSpeechService.speak`, with the role
/// the call site asks for: [kTeacherRole], a dialogue speaker label, or
/// [kPartnerSpeaker].
///
/// Mirrors `tool/audio/mohingo_audio/speakables.py`. The level gate
/// (`test/content/levels/level_audio_test.dart`) holds a level's audio
/// manifest to this list, so a new call site in the app must be added to
/// both, or the gate fails and says so. See ADR 0008.
class Speakable {
  const Speakable({
    required this.text,
    required this.role,
    required this.source,
  });

  final String text;
  final String role;

  /// Where in the bundle the string comes from, for a failure message.
  final String source;
}

List<Speakable> speakableStringsOf(CourseBundle bundle) {
  final out = <Speakable>[];

  void add(String? text, String role, String source) {
    final t = text?.trim();
    if (t == null || t.isEmpty) return;
    out.add(Speakable(text: t, role: role, source: source));
  }

  void activity(Activity a, String where) {
    // The listening card speaks an audio-choice transcript in the teacher
    // voice; the speaking view reads the partner's turns in the partner
    // voice. No other activity type is spoken.
    if (a is AudioChoiceActivity) {
      add(a.audioTranscript, kTeacherRole, '$where/${a.id}.audioTranscript');
    }
    if (a is SpeakActivity) {
      for (final (i, turn) in a.partnerTurns.indexed) {
        add(turn, kPartnerSpeaker, '$where/${a.id}.partnerTurns[$i]');
      }
    }
  }

  for (final u in bundle.units) {
    for (final l in u.lessons) {
      for (final (i, line) in l.encounterDialogue.indexed) {
        add(line.en, line.speaker, '${l.id} dialogue[$i]');
      }
      add(l.readingText?.text, kTeacherRole, '${l.id} readingText');
      for (final a in l.activities) {
        activity(a, l.id);
      }
    }
  }
  for (final c in bundle.chunks) {
    add(c.text, kTeacherRole, 'chunk ${c.id}');
  }
  for (final x in bundle.lexicon) {
    add(x.headword, kTeacherRole, 'lexicon ${x.id}');
    for (final (i, ex) in x.examples.indexed) {
      add(ex.en, kTeacherRole, 'lexicon ${x.id} example[$i]');
    }
  }
  for (final g in bundle.grammar) {
    add(g.form, kTeacherRole, 'grammar ${g.id}');
    for (final (i, ex) in g.examples.indexed) {
      add(ex.en, kTeacherRole, 'grammar ${g.id} example[$i]');
    }
  }
  for (final a in bundle.finalMission.activities) {
    activity(a, 'finalMission');
  }
  for (final e in bundle.finalAssessment.sections.entries) {
    for (final a in e.value.activities) {
      activity(a, 'finalAssessment.${e.key}');
    }
  }
  return out;
}
