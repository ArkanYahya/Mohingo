import 'package:llamadart/llamadart.dart';

import 'benchmark_cases.dart';

/// The fixed instruction every candidate gets. It mirrors what the main app's
/// `LocalJudgementService` will ask (ADR 0013): does the answer do the task,
/// how many grammar issues, and a short explanation in English and Arabic.
const String kJudgeSystemPrompt =
    'You are an English teacher grading one short answer from an adult '
    'learner of English (CEFR level A1 to A2) whose first language is '
    'Arabic. You get the TASK, one MODEL ANSWER (an example of a good '
    'answer; an answer with different words or a different topic can be just '
    'as good) and the LEARNER ANSWER.\n'
    'Decide:\n'
    '1. answers_task: true only if the learner answer is written in English '
    'and does everything the task asks. False if a required part is missing, '
    'if it is off topic, if it only repeats the task, or if it is not '
    'English.\n'
    '2. grammar_issues: the number of grammar or spelling mistakes in the '
    'learner answer (0 if none). Do not count style or punctuation.\n'
    '3. corrected: the learner answer with those mistakes fixed, keeping the '
    'learner\'s own words where possible.\n'
    '4. explanation_en: one or two short, friendly sentences in simple '
    'English: what was good, and what to fix or add.\n'
    '5. explanation_ar: the same explanation written in Arabic.\n'
    'Reply with JSON only.';

/// The JSON the model must produce; constrained decoding enforces it.
const Map<String, dynamic> kJudgementSchema = {
  'type': 'object',
  'properties': {
    'answers_task': {'type': 'boolean'},
    'grammar_issues': {'type': 'integer', 'minimum': 0, 'maximum': 20},
    'corrected': {'type': 'string'},
    'explanation_en': {'type': 'string'},
    'explanation_ar': {'type': 'string'},
  },
  'required': [
    'answers_task',
    'grammar_issues',
    'corrected',
    'explanation_en',
    'explanation_ar',
  ],
  'additionalProperties': false,
};

/// Deterministic decoding: the same answer must get the same judgement on
/// every run (ADR 0013, alternatives: "the model's judgement as the grade").
const GenerationParams kJudgeGenerationParams = GenerationParams(
  maxTokens: 320,
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

List<LlamaChatMessage> judgeMessages(BenchmarkCase c) => [
  const LlamaChatMessage.fromText(
    role: LlamaChatRole.system,
    text: kJudgeSystemPrompt,
  ),
  LlamaChatMessage.fromText(role: LlamaChatRole.user, text: judgeUserPrompt(c)),
];

/// One model's judgement of one answer.
class SpikeJudgement {
  const SpikeJudgement({
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
      answersTask: answers,
      grammarIssues: issues < 0 ? 0 : issues,
      corrected: (json['corrected'] as String?) ?? '',
      explanationEn: (json['explanation_en'] as String?) ?? '',
      explanationAr: (json['explanation_ar'] as String?) ?? '',
    );
  }

  final bool answersTask;
  final int grammarIssues;
  final String corrected;
  final String explanationEn;
  final String explanationAr;

  /// Whether the Arabic field holds Arabic letters at all (a model that
  /// cannot write Arabic tends to repeat the English or leave it empty).
  bool get explanationArIsArabic => RegExp(r'[؀-ۿ]').hasMatch(explanationAr);
}

LlamaStructuredOutput<SpikeJudgement> judgementOutput() =>
    LlamaStructuredOutput.jsonSchema(
      schema: kJudgementSchema,
      decoder: SpikeJudgement.fromJson,
      name: 'judgement',
    );
