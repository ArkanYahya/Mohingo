import 'package:llamadart/llamadart.dart';

import 'benchmark_cases.dart';

/// What the model is asked to produce. `fast` asks for the verdict, the
/// grammar count and a one-line English explanation; `full` adds the
/// corrected answer and an Arabic explanation. The first run on a phone
/// (Gemma 3 1B, 2026-10-23) spent most of its 15 s per answer generating
/// ~100 tokens of explanation, so the two are measured apart.
enum JudgeMode { fast, full }

/// The fixed instruction every candidate gets. It mirrors what the main
/// app's `LocalJudgementService` will ask (ADR 0013): does the answer do
/// the task, how many grammar issues, and a short explanation.
///
/// The first run showed a 1B model saying yes to all 22 answers and
/// opening every explanation with "Good!", so the prompt now makes the
/// model check the task's parts *before* it gives a verdict (the fields
/// come in that order in the JSON), tells it to be strict, and shows one
/// failing and one passing example.
String judgeSystemPrompt(JudgeMode mode) =>
    'You are a strict English teacher grading one short answer from an '
    'adult learner of English (CEFR A1 to A2) whose first language is '
    'Arabic. You get the TASK, one MODEL ANSWER (an example of a good '
    'answer; an answer with different words or a different topic can be '
    'just as good) and the LEARNER ANSWER.\n'
    'Work in this order:\n'
    '1. is_english: true only if the learner answer is written in English.\n'
    '2. missing: list every part the TASK asks for that the learner answer '
    'does not do, in a few words. Write "nothing" only if every part is '
    'done. An answer that is off topic, that only repeats the task, that '
    'is one word, or that does the wrong thing is missing everything.\n'
    '3. answers_task: true only if is_english is true and missing is '
    '"nothing". Most learner answers have a problem; do not be kind here.\n'
    '4. grammar_issues: the number of grammar or spelling mistakes in the '
    'learner answer. 0 if there are none. Do not count style or '
    'punctuation.\n'
    '${mode == JudgeMode.full ? '5. corrected: the learner answer with those mistakes fixed, keeping the learner\'s own words. If the answer is not English or is off topic, copy it unchanged.\n6' : '5'}'
    '. explanation_en: one short sentence in simple English. If something '
    'is missing or wrong, say what. If all is well, say what was done '
    'well. Never start with "Good" when something is missing.\n'
    '${mode == JudgeMode.full ? '7. explanation_ar: the same sentence written in Arabic script, in Arabic (not Bengali, not Chinese, not English).\n' : ''}'
    'Example 1. TASK: Say two things you like and one thing you don\'t '
    'like. LEARNER ANSWER: I like tea. I like coffee too. -> is_english '
    'true, missing "one thing you don\'t like", answers_task false, '
    'grammar_issues 0.\n'
    'Example 2. TASK: Ask for the price of the shoes. LEARNER ANSWER: '
    'Excuse me, how much are this shoes? -> is_english true, missing '
    '"nothing", answers_task true, grammar_issues 1 (this -> these).\n'
    'Reply with JSON only.';

/// The JSON the model must produce; constrained decoding enforces it. The
/// checks come before the verdict so the verdict is conditioned on them.
Map<String, dynamic> judgementSchema(JudgeMode mode) => {
  'type': 'object',
  'properties': {
    'is_english': {'type': 'boolean'},
    'missing': {'type': 'string'},
    'answers_task': {'type': 'boolean'},
    'grammar_issues': {'type': 'integer', 'minimum': 0, 'maximum': 20},
    if (mode == JudgeMode.full) 'corrected': {'type': 'string'},
    'explanation_en': {'type': 'string'},
    if (mode == JudgeMode.full) 'explanation_ar': {'type': 'string'},
  },
  'required': [
    'is_english',
    'missing',
    'answers_task',
    'grammar_issues',
    if (mode == JudgeMode.full) 'corrected',
    'explanation_en',
    if (mode == JudgeMode.full) 'explanation_ar',
  ],
  'additionalProperties': false,
};

/// Deterministic decoding: the same answer must get the same judgement on
/// every run (ADR 0013, alternatives: "the model's judgement as the grade").
GenerationParams judgeGenerationParams(JudgeMode mode) => GenerationParams(
  maxTokens: mode == JudgeMode.full ? 320 : 120,
  temp: 0.0,
  topK: 1,
  topP: 1.0,
  minP: 0.0,
  penalty: 1.0,
  seed: 7,
);

String judgeUserPrompt(BenchmarkCase c) =>
    'TASK: ${c.task}\n'
    'MODEL ANSWER: ${c.modelAnswer}\n'
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

/// One model's judgement of one answer.
class SpikeJudgement {
  const SpikeJudgement({
    required this.isEnglish,
    required this.missing,
    required this.answersTask,
    required this.grammarIssues,
    required this.corrected,
    required this.explanationEn,
    required this.explanationAr,
  });

  factory SpikeJudgement.fromJson(Map<String, dynamic> json) {
    final answers = json['answers_task'];
    final issues = json['grammar_issues'];
    if (answers is! bool) {
      throw const FormatException('answers_task must be a boolean');
    }
    if (issues is! int) {
      throw const FormatException('grammar_issues must be an integer');
    }
    return SpikeJudgement(
      isEnglish: json['is_english'] is bool ? json['is_english'] as bool : true,
      missing: (json['missing'] as String?) ?? '',
      answersTask: answers,
      grammarIssues: issues < 0 ? 0 : issues,
      corrected: (json['corrected'] as String?) ?? '',
      explanationEn: (json['explanation_en'] as String?) ?? '',
      explanationAr: (json['explanation_ar'] as String?) ?? '',
    );
  }

  final bool isEnglish;
  final String missing;
  final bool answersTask;
  final int grammarIssues;
  final String corrected;
  final String explanationEn;
  final String explanationAr;

  /// Whether the Arabic field is actually Arabic. The first run produced
  /// Bengali and Chinese there, and one Arabic word in a Bengali sentence
  /// must not count.
  bool get explanationArIsArabic =>
      dominantScript(explanationAr) == Script.arabic;
}

LlamaStructuredOutput<SpikeJudgement> judgementOutput(JudgeMode mode) =>
    LlamaStructuredOutput.jsonSchema(
      schema: judgementSchema(mode),
      decoder: SpikeJudgement.fromJson,
      name: 'judgement',
    );
