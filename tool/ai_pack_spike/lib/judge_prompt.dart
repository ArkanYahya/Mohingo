import 'package:llamadart/llamadart.dart';

import 'benchmark_cases.dart';

/// What the model is asked to produce. `fast` asks for the part checks, the
/// mistakes and a one-line English explanation; `full` adds the corrected
/// answer and an Arabic explanation.
enum JudgeMode { fast, full }

/// Prompt v4. Run 3 (LFM2.5 1.2B on v3) copied its "mistakes" and half its
/// explanations from the MODEL ANSWER — "I don't like tennis" listed as the
/// learner's mistake on an answer about tea and milk — so the model answer
/// is no longer shown to the model at all: the parts carry the requirement,
/// and there is nothing left to copy from.
///
/// Prompt v3. The first two runs (Gemma 3 1B, LFM2.5 1.2B, 2026-10-23)
/// showed that a model of this size cannot be asked for a verdict: both
/// said yes to all 22 answers, and the second copied the prompt's worked
/// example into every `missing` field. So the model is no longer asked to
/// judge, count or decide anything:
///
/// - The task's requirements are listed for it (the case's `parts`, in
///   Mohingo the rubric's groups) and it answers true/false per part; the
///   JSON fixes the part names, so it only ever produces the booleans.
/// - Grammar mistakes come back as a list of (wrong, right) pairs; code
///   counts them. A list is easier for a small model than a number.
/// - Whether the answer is English is decided by code from its script,
///   never asked.
/// - The verdict is computed: English and every part done.
///
/// No worked example: it contaminated the previous output.
String judgeSystemPrompt(JudgeMode mode) =>
    'You check one short answer written by an adult beginner learning '
    'English (CEFR A1 to A2). You get the TASK, its parts, and the LEARNER '
    'ANSWER.\n'
    'For each part of the task listed in "parts", say whether the learner '
    'answer really does it: true or false. Read only the learner answer. If '
    'the learner answer does not do a part, or talks about something else, '
    'or only repeats the task, that part is false.\n'
    'In "mistakes", list each grammar or spelling mistake in the learner '
    'answer as the wrong words and the right words. Leave the list empty '
    'when there are none. Do not list style or punctuation.\n'
    '${mode == JudgeMode.full ? 'In "corrected", give the learner answer with the mistakes fixed, keeping the learner\'s words.\n' : ''}'
    'In "explanation_en", write one short sentence in simple English for '
    'the learner: what is missing or wrong, or, if nothing is, what was done '
    'well.\n'
    '${mode == JudgeMode.full ? 'In "explanation_ar", write that sentence in Arabic, in Arabic script.\n' : ''}'
    'Reply with JSON only.';

/// The JSON the model must produce; constrained decoding enforces it, and
/// the part names are fixed by the schema so the model emits only booleans.
Map<String, dynamic> judgementSchema(JudgeMode mode, List<String> parts) => {
  'type': 'object',
  'properties': {
    'parts': {
      'type': 'array',
      'minItems': parts.length,
      'maxItems': parts.length,
      'prefixItems': [
        for (final part in parts)
          {
            'type': 'object',
            'properties': {
              'part': {'const': part},
              'done': {'type': 'boolean'},
            },
            'required': ['part', 'done'],
            'additionalProperties': false,
          },
      ],
    },
    'mistakes': {
      'type': 'array',
      'maxItems': 6,
      'items': {
        'type': 'object',
        'properties': {
          'wrong': {'type': 'string'},
          'right': {'type': 'string'},
        },
        'required': ['wrong', 'right'],
        'additionalProperties': false,
      },
    },
    if (mode == JudgeMode.full) 'corrected': {'type': 'string'},
    'explanation_en': {'type': 'string'},
    if (mode == JudgeMode.full) 'explanation_ar': {'type': 'string'},
  },
  'required': [
    'parts',
    'mistakes',
    if (mode == JudgeMode.full) 'corrected',
    'explanation_en',
    if (mode == JudgeMode.full) 'explanation_ar',
  ],
  'additionalProperties': false,
};

/// Deterministic decoding: the same answer must get the same judgement on
/// every run (ADR 0013, alternatives: "the model's judgement as the grade").
GenerationParams judgeGenerationParams(JudgeMode mode) => GenerationParams(
  maxTokens: mode == JudgeMode.full ? 360 : 200,
  temp: 0.0,
  topK: 1,
  topP: 1.0,
  minP: 0.0,
  penalty: 1.0,
  seed: 7,
);

String judgeUserPrompt(BenchmarkCase c) =>
    'TASK: ${c.task}\n'
    'parts: ${c.parts.map((p) => '"$p"').join(', ')}\n'
    'LEARNER ANSWER: ${c.answer}';

List<LlamaChatMessage> judgeMessages(BenchmarkCase c, JudgeMode mode) => [
  LlamaChatMessage.fromText(
    role: LlamaChatRole.system,
    text: judgeSystemPrompt(mode),
  ),
  LlamaChatMessage.fromText(role: LlamaChatRole.user, text: judgeUserPrompt(c)),
];

/// The writing system most of a text's letters belong to.
enum Script { arabic, latin, bengali, cjk, other, none }

Script dominantScript(String text) {
  var arabic = 0, latin = 0, bengali = 0, cjk = 0, other = 0;
  for (final r in text.runes) {
    if (r >= 0x0600 && r <= 0x06FF || r >= 0x0750 && r <= 0x077F) {
      arabic++;
    } else if (r >= 0x41 && r <= 0x5A || r >= 0x61 && r <= 0x7A) {
      latin++;
    } else if (r >= 0x0980 && r <= 0x09FF) {
      bengali++;
    } else if (r >= 0x3040 && r <= 0x30FF || r >= 0x4E00 && r <= 0x9FFF) {
      cjk++;
    } else if (r > 0x7F && !(r >= 0x2000 && r <= 0x206F)) {
      other++;
    }
  }
  final total = arabic + latin + bengali + cjk + other;
  if (total == 0) return Script.none;
  final best = [
    (Script.arabic, arabic),
    (Script.latin, latin),
    (Script.bengali, bengali),
    (Script.cjk, cjk),
    (Script.other, other),
  ].reduce((a, b) => b.$2 > a.$2 ? b : a);
  // A text counts as a script only when that script clearly carries it.
  return best.$2 * 10 >= total * 6 ? best.$1 : Script.other;
}

/// Code's own check: an answer in Latin script is treated as English.
bool looksEnglish(String answer) => dominantScript(answer) == Script.latin;

/// One grammar mistake the model listed.
class Mistake {
  const Mistake({required this.wrong, required this.right});
  final String wrong;
  final String right;

  @override
  String toString() => '"$wrong" -> "$right"';
}

/// One model's judgement of one answer, with the verdict computed by code.
class SpikeJudgement {
  const SpikeJudgement({
    required this.partsDone,
    required this.mistakes,
    required this.corrected,
    required this.explanationEn,
    required this.explanationAr,
    required this.isEnglish,
  });

  /// [parts] are the case's part names, in order; [answer] is the learner
  /// answer, read by code for its script.
  factory SpikeJudgement.fromJson(
    Map<String, dynamic> json, {
    required List<String> parts,
    required String answer,
  }) {
    final rawParts = json['parts'];
    if (rawParts is! List) {
      throw const FormatException('parts must be a list');
    }
    final done = <String, bool>{};
    for (var i = 0; i < parts.length; i++) {
      final item = i < rawParts.length ? rawParts[i] : null;
      final flag = item is Map ? item['done'] : null;
      if (flag is! bool) {
        throw FormatException('parts[$i].done must be a boolean');
      }
      done[parts[i]] = flag;
    }
    final rawMistakes = json['mistakes'];
    final mistakes = <Mistake>[
      if (rawMistakes is List)
        for (final m in rawMistakes)
          if (m is Map)
            Mistake(
              wrong: (m['wrong'] as String?) ?? '',
              right: (m['right'] as String?) ?? '',
            ),
    ];
    return SpikeJudgement(
      partsDone: done,
      mistakes: mistakes,
      corrected: (json['corrected'] as String?) ?? '',
      explanationEn: (json['explanation_en'] as String?) ?? '',
      explanationAr: (json['explanation_ar'] as String?) ?? '',
      isEnglish: looksEnglish(answer),
    );
  }

  final Map<String, bool> partsDone;
  final List<Mistake> mistakes;
  final String corrected;
  final String explanationEn;
  final String explanationAr;

  /// Decided by code from the answer's script, not by the model.
  final bool isEnglish;

  /// The verdict: English, and every part done.
  bool get answersTask => isEnglish && partsDone.values.every((d) => d);

  /// The grammar count the main app would use (`LocalJudgement.grammarIssues`).
  int get grammarIssues => mistakes.length;

  /// Whether the Arabic field is actually Arabic (the first run produced
  /// Bengali and Chinese there).
  bool get explanationArIsArabic =>
      dominantScript(explanationAr) == Script.arabic;
}

LlamaStructuredOutput<SpikeJudgement> judgementOutput(
  JudgeMode mode,
  BenchmarkCase c,
) => LlamaStructuredOutput.jsonSchema(
  schema: judgementSchema(mode, c.parts),
  decoder: (json) =>
      SpikeJudgement.fromJson(json, parts: c.parts, answer: c.answer),
  name: 'judgement',
);
