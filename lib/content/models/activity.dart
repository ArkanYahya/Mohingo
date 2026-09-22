import 'domain_definitions.dart';
import 'evaluation_spec.dart';
import 'exceptions.dart';
import 'non_blank.dart';

/// One typed exercise, discriminated by [type].
///
/// Every subtype carries the fields actually needed to render and grade it,
/// per docs/DATA_MODEL.md — plus [raw], the complete original JSON object,
/// so no bundle field is ever silently lost even if this Phase-4 model
/// doesn't give it a dedicated typed getter (e.g. `assessmentMode`,
/// `sourcePolicy`, `examinerTurns` — present on some activities but not yet
/// acted on by app logic).
///
/// Never expose [answer]/[accepted]/[evaluation] fields to UI state, logs, or
/// accessibility labels before submission — see docs/ARCHITECTURE.md's
/// non-negotiable curriculum-integration rules.
sealed class Activity {
  const Activity({
    required this.id,
    required this.lessonId,
    required this.mode,
    required this.skill,
    required this.canDo,
    required this.prompt,
    required this.promptAr,
    required this.raw,
  });

  final String id;

  /// Null for placement/final-mission/final-assessment items, which use
  /// their own id namespace instead of a lesson.
  final String? lessonId;
  final ActivityMode mode;
  final Skill skill;
  final List<String> canDo;
  final String prompt;
  final String? promptAr;
  final Map<String, dynamic> raw;

  /// Material the learner works from — a notice, a timetable, two short
  /// profiles — shown as a card with the question. Any activity type may
  /// carry one (A1's final-assessment mediation tasks and A2's mediation
  /// tasks do). Null when absent or blank.
  String? get sourceCard => nonBlank(raw['sourceCard']);

  static Activity fromJson(Map<String, dynamic> json) {
    final type = json['type'] as String;
    return switch (type) {
      'audioChoice' => AudioChoiceActivity._fromJson(json),
      'textChoice' => TextChoiceActivity._fromJson(json),
      'match' => MatchActivity._fromJson(json),
      'order' => OrderActivity._fromJson(json),
      'gap' => GapActivity._fromJson(json),
      'form' => FormActivity._fromJson(json),
      'speak' => SpeakActivity._fromJson(json),
      'write' => WriteActivity._fromJson(json),
      'dialogue' => DialogueActivity._fromJson(json),
      _ => throw UnsupportedContentSchemaException(
        'Unknown activity type: $type',
      ),
    };
  }

  static ({
    String id,
    String? lessonId,
    ActivityMode mode,
    Skill skill,
    List<String> canDo,
    String prompt,
    String? promptAr,
  })
  _common(Map<String, dynamic> json) {
    return (
      id: json['id'] as String,
      lessonId: json['lessonId'] as String?,
      mode: ActivityMode.parse(json['mode'] as String),
      skill: Skill.parse(json['skill'] as String),
      canDo: List<String>.from(json['canDo'] as List? ?? const []),
      prompt: json['prompt'] as String,
      promptAr: json['promptAr'] as String?,
    );
  }
}

class AudioChoiceActivity extends Activity {
  const AudioChoiceActivity({
    required super.id,
    required super.lessonId,
    required super.mode,
    required super.skill,
    required super.canDo,
    required super.prompt,
    required super.promptAr,
    required super.raw,
    required this.options,
    required this.answer,
    this.audioTranscript,
  });

  factory AudioChoiceActivity._fromJson(Map<String, dynamic> json) {
    final c = Activity._common(json);
    return AudioChoiceActivity(
      id: c.id,
      lessonId: c.lessonId,
      mode: c.mode,
      skill: c.skill,
      canDo: c.canDo,
      prompt: c.prompt,
      promptAr: c.promptAr,
      raw: json,
      options: List<String>.from(json['options'] as List),
      answer: json['answer'] as String,
      audioTranscript: json['audioTranscript'] as String?,
    );
  }

  final List<String> options;
  final String answer;

  /// What the learner hears: played from the level's bundled clip, or read
  /// by the device engine when there is none (ADR 0008). See
  /// docs/DATA_MODEL.md.
  final String? audioTranscript;
}

class TextChoiceActivity extends Activity {
  const TextChoiceActivity({
    required super.id,
    required super.lessonId,
    required super.mode,
    required super.skill,
    required super.canDo,
    required super.prompt,
    required super.promptAr,
    required super.raw,
    required this.options,
    required this.answer,
    this.sourceText,
  });

  factory TextChoiceActivity._fromJson(Map<String, dynamic> json) {
    final c = Activity._common(json);
    return TextChoiceActivity(
      id: c.id,
      lessonId: c.lessonId,
      mode: c.mode,
      skill: c.skill,
      canDo: c.canDo,
      prompt: c.prompt,
      promptAr: c.promptAr,
      raw: json,
      options: List<String>.from(json['options'] as List),
      answer: json['answer'] as String,
      sourceText: nonBlank(json['sourceText']),
    );
  }

  final List<String> options;
  final String answer;

  /// Null when absent or blank — a blank value must never shadow a real
  /// [Activity.sourceCard] (see `ChoiceActivityView.textChoice`, which
  /// falls back to it).
  final String? sourceText;
}

class MatchActivity extends Activity {
  const MatchActivity({
    required super.id,
    required super.lessonId,
    required super.mode,
    required super.skill,
    required super.canDo,
    required super.prompt,
    required super.promptAr,
    required super.raw,
    required this.pairs,
  });

  factory MatchActivity._fromJson(Map<String, dynamic> json) {
    final c = Activity._common(json);
    return MatchActivity(
      id: c.id,
      lessonId: c.lessonId,
      mode: c.mode,
      skill: c.skill,
      canDo: c.canDo,
      prompt: c.prompt,
      promptAr: c.promptAr,
      raw: json,
      pairs: (json['pairs'] as List)
          .map((pair) => List<String>.from(pair as List))
          .toList(),
    );
  }

  /// Each entry is a `[left, right]` pair.
  final List<List<String>> pairs;
}

class OrderActivity extends Activity {
  const OrderActivity({
    required super.id,
    required super.lessonId,
    required super.mode,
    required super.skill,
    required super.canDo,
    required super.prompt,
    required super.promptAr,
    required super.raw,
    required this.tokens,
    required this.answer,
  });

  factory OrderActivity._fromJson(Map<String, dynamic> json) {
    final c = Activity._common(json);
    return OrderActivity(
      id: c.id,
      lessonId: c.lessonId,
      mode: c.mode,
      skill: c.skill,
      canDo: c.canDo,
      prompt: c.prompt,
      promptAr: c.promptAr,
      raw: json,
      tokens: List<String>.from(json['tokens'] as List),
      answer: List<String>.from(json['answer'] as List),
    );
  }

  final List<String> tokens;
  final List<String> answer;
}

class GapActivity extends Activity {
  const GapActivity({
    required super.id,
    required super.lessonId,
    required super.mode,
    required super.skill,
    required super.canDo,
    required super.prompt,
    required super.promptAr,
    required super.raw,
    required this.text,
    required this.options,
    required this.answer,
  });

  factory GapActivity._fromJson(Map<String, dynamic> json) {
    final c = Activity._common(json);
    return GapActivity(
      id: c.id,
      lessonId: c.lessonId,
      mode: c.mode,
      skill: c.skill,
      canDo: c.canDo,
      prompt: c.prompt,
      promptAr: c.promptAr,
      raw: json,
      text: json['text'] as String,
      options: List<String>.from(json['options'] as List),
      answer: json['answer'] as String,
    );
  }

  /// The sentence with a `___` gap to fill.
  final String text;
  final List<String> options;
  final String answer;
}

class FormActivity extends Activity {
  const FormActivity({
    required super.id,
    required super.lessonId,
    required super.mode,
    required super.skill,
    required super.canDo,
    required super.prompt,
    required super.promptAr,
    required super.raw,
    required this.fields,
    this.evaluation,
  });

  factory FormActivity._fromJson(Map<String, dynamic> json) {
    final c = Activity._common(json);
    return FormActivity(
      id: c.id,
      lessonId: c.lessonId,
      mode: c.mode,
      skill: c.skill,
      canDo: c.canDo,
      prompt: c.prompt,
      promptAr: c.promptAr,
      raw: json,
      fields: List<String>.from(json['fields'] as List),
      evaluation: EvaluationSpec.fromJson(json['evaluation']),
    );
  }

  final List<String> fields;

  /// A structured grading rubric, task-specific, never a single overall
  /// score. `null` for a not-yet-migrated legacy rubric-name string or an
  /// absent field. See docs/DATA_MODEL.md.
  final EvaluationSpec? evaluation;
}

class SpeakActivity extends Activity {
  const SpeakActivity({
    required super.id,
    required super.lessonId,
    required super.mode,
    required super.skill,
    required super.canDo,
    required super.prompt,
    required super.promptAr,
    required super.raw,
    required this.accepted,
    this.evaluation,
    this.fallbackSkill,
  });

  factory SpeakActivity._fromJson(Map<String, dynamic> json) {
    final c = Activity._common(json);
    return SpeakActivity(
      id: c.id,
      lessonId: c.lessonId,
      mode: c.mode,
      skill: c.skill,
      canDo: c.canDo,
      prompt: c.prompt,
      promptAr: c.promptAr,
      raw: json,
      accepted: List<String>.from(json['accepted'] as List? ?? const []),
      evaluation: EvaluationSpec.fromJson(json['evaluation']),
      fallbackSkill: json['fallbackSkill'] as String?,
    );
  }

  final List<String> accepted;
  final EvaluationSpec? evaluation;

  /// The typed-answer accessibility fallback skill (e.g. `"writing"`) —
  /// answering via this fallback must be recorded with `wasFallback=true`
  /// and `evidenceSkill` set to this value, never as speaking evidence. See
  /// docs/DATA_MODEL.md.
  final String? fallbackSkill;

  /// What the other person says, read aloud before the learner answers —
  /// the bundle's `partnerTurns`, or A1's older `examinerTurns`. Empty
  /// when the task has none.
  List<String> get partnerTurns {
    final value = raw['partnerTurns'] ?? raw['examinerTurns'];
    if (value is! List) return const [];
    return [
      for (final turn in value)
        if (turn is String && turn.trim().isNotEmpty) turn,
    ];
  }
}

class WriteActivity extends Activity {
  const WriteActivity({
    required super.id,
    required super.lessonId,
    required super.mode,
    required super.skill,
    required super.canDo,
    required super.prompt,
    required super.promptAr,
    required super.raw,
    required this.accepted,
    this.evaluation,
    this.wordGuide,
  });

  factory WriteActivity._fromJson(Map<String, dynamic> json) {
    final c = Activity._common(json);
    return WriteActivity(
      id: c.id,
      lessonId: c.lessonId,
      mode: c.mode,
      skill: c.skill,
      canDo: c.canDo,
      prompt: c.prompt,
      promptAr: c.promptAr,
      raw: json,
      accepted: List<String>.from(json['accepted'] as List? ?? const []),
      evaluation: EvaluationSpec.fromJson(json['evaluation']),
      wordGuide: json['wordGuide'] == null
          ? null
          : List<int>.from(json['wordGuide'] as List),
    );
  }

  final List<String> accepted;
  final EvaluationSpec? evaluation;

  /// `[min, max]` suggested word count, when the bundle declares one.
  final List<int>? wordGuide;
}

/// Declared in `domain.ACTIVITY_TYPES` but with **no authored instances** in
/// the current bundle (verified this session) — modeled minimally (common
/// fields + [raw] only) since there's no real schema to go on yet. The
/// activity-renderer registry must still support this type; it can only be
/// tested against a hand-authored fixture until real content exists. See
/// docs/TESTING.md.
class DialogueActivity extends Activity {
  const DialogueActivity({
    required super.id,
    required super.lessonId,
    required super.mode,
    required super.skill,
    required super.canDo,
    required super.prompt,
    required super.promptAr,
    required super.raw,
  });

  factory DialogueActivity._fromJson(Map<String, dynamic> json) {
    final c = Activity._common(json);
    return DialogueActivity(
      id: c.id,
      lessonId: c.lessonId,
      mode: c.mode,
      skill: c.skill,
      canDo: c.canDo,
      prompt: c.prompt,
      promptAr: c.promptAr,
      raw: json,
    );
  }
}
