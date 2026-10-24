import 'dart:convert';

import '../../../../content/models/evaluation_spec.dart';

/// The pass bar every free answer is held to — the same value
/// `MasteryPolicy.minimumObjectiveScore` carries in both shipped bundles, and
/// the one `PendingRefinementDrainService` has always finalized against.
const double kFreeAnswerPassScore = 0.75;

/// The most every signal together may move a rubric's score, in either
/// direction — a quarter of the scale. A rubric score of 0 can therefore
/// never pass and a rubric score of 1 can never fall below the pass bar.
/// See docs/adr/0013-on-device-ai-for-free-answers.md, decision 2.
const double kMaxSignalAdjustment = 0.25;

/// How much a full meaning match may add — only ever when the rubric left
/// room (base below 1).
const double kMeaningWeight = 0.25;

/// How much a maximally error-dense answer may lose to grammar.
const double kGrammarWeight = 0.25;

/// How much a local yes/no judgement of the meaning moves the score, up
/// when it agrees the answer does the task, down when it does not. Reserved
/// for a future local grammar judgement (ADR 0014); nothing sets it today.
const double kJudgementWeight = 0.10;

/// The entailment probability at which the inference model is taken to say
/// an answer does what a group means (ADR 0014). The most likely of the
/// model's three classes, no more: measured on the device spike, right
/// answers scored 0.58-0.98 and wrong ones 0.00-0.42.
const double kEntailmentThreshold = 0.5;

/// Which groups an answer meets, by its words or by its meaning: a group
/// the rubric matched counts as met whatever the model says, so the model
/// can only add. Both lists are per group, in order.
List<bool> groupsMet({
  required List<bool> metByKeyword,
  required List<double> entailment,
}) => [
  for (var i = 0; i < metByKeyword.length; i++)
    metByKeyword[i] ||
        (i < entailment.length && entailment[i] >= kEntailmentThreshold),
];

/// The meaning signal of ADR 0014: the share of a rubric's groups the answer
/// meets by words or by meaning, 0..1. Feeds [GradingSignals.meaning] with
/// the same weight and bound as the similarity signal it replaces where
/// meanings are authored, so an answer that meets one group of two by its
/// words and the other by its meaning scores 0.5 + 0.25 = 0.75, the pass
/// bar, and an answer that meets neither stays at 0.
double meaningFromParts({
  required List<bool> metByKeyword,
  required List<double> entailment,
}) {
  if (metByKeyword.isEmpty) return 0;
  final met = groupsMet(metByKeyword: metByKeyword, entailment: entailment);
  return met.where((m) => m).length / met.length;
}

/// The groups an answer meets neither by words nor by meaning — what the
/// feedback panel names for the learner, in the group's own words.
List<GroupMeaning> missingMeanings({
  required List<GroupMeaning> meanings,
  required List<bool> metByKeyword,
  required List<double> entailment,
}) {
  final met = groupsMet(metByKeyword: metByKeyword, entailment: entailment);
  return [
    for (var i = 0; i < meanings.length && i < met.length; i++)
      if (!met[i]) meanings[i],
  ];
}

/// Everything known about one free answer when its grade is decided.
///
/// [rubric] is the rubric's own score (`evaluate()`), the base nothing else
/// may replace. The rest are optional: [meaning] is the on-device meaning
/// signal (0 = nothing like any model answer, 1 = says the same thing),
/// [grammarPenalty] the error density mapped to 0..1 (from a local grammar model, or
/// LanguageTool for a learner without it), [meaningOk] the pack's judgement.
/// Any of them may be absent and the rule still works.
class GradingSignals {
  const GradingSignals({
    required this.rubric,
    this.meaning,
    this.grammarPenalty,
    this.meaningOk,
    this.pack,
  });

  final double rubric;
  final double? meaning;
  final double? grammarPenalty;
  final bool? meaningOk;

  /// `<name>-<version>` of the local model that judged this answer, if one did.
  final String? pack;

  GradingSignals copyWith({
    double? meaning,
    double? grammarPenalty,
    bool? meaningOk,
    String? pack,
  }) => GradingSignals(
    rubric: rubric,
    meaning: meaning ?? this.meaning,
    grammarPenalty: grammarPenalty ?? this.grammarPenalty,
    meaningOk: meaningOk ?? this.meaningOk,
    pack: pack ?? this.pack,
  );
}

/// The one combination rule (docs/superpowers/specs/
/// 2026-10-22-on-device-free-answer-grading-design.md, decision 3):
///
/// ```
/// adjust = +kMeaningWeight × meaning        (only when rubric < 1)
///          − kGrammarWeight × grammarPenalty
///          + kJudgementWeight × (meaningOk ? 1 : −1)
/// adjust = clamp(adjust, −kMaxSignalAdjustment, +kMaxSignalAdjustment)
/// final  = clamp(rubric + adjust, 0, 1)
/// ```
///
/// Pure and deterministic: the same signals always give the same score.
double combineSignals(GradingSignals s) {
  var adjust = 0.0;
  final meaning = s.meaning;
  if (meaning != null && s.rubric < 1.0) {
    adjust += kMeaningWeight * meaning.clamp(0.0, 1.0);
  }
  final grammarPenalty = s.grammarPenalty;
  if (grammarPenalty != null) {
    adjust -= kGrammarWeight * grammarPenalty.clamp(0.0, 1.0);
  }
  final meaningOk = s.meaningOk;
  if (meaningOk != null) {
    adjust += kJudgementWeight * (meaningOk ? 1 : -1);
  }
  adjust = adjust.clamp(-kMaxSignalAdjustment, kMaxSignalAdjustment);
  return (s.rubric.clamp(0.0, 1.0) + adjust).clamp(0.0, 1.0);
}

/// Whether a free answer graded at submission counts as correct: the rubric's
/// own verdict stands, and a signal may only add a pass it raised the score
/// to — never on a score the rubric alone produced. Without any signal the
/// verdict is exactly the rubric's, so a build with no embedding model
/// grades as it always has.
bool passesWithSignals({
  required bool rubricCorrect,
  required double rubricScore,
  required double finalScore,
}) =>
    rubricCorrect ||
    (finalScore > rubricScore && finalScore >= kFreeAnswerPassScore);

/// Grammar issues as a 0..1 penalty: four issues in a hundred words is the
/// most an answer can be penalised for. The same density mapping the online
/// grammar check has used since ADR 0005; a zero word count counts as one so
/// an empty report never divides by zero.
double grammarPenaltyOf({required int errorCount, required int wordCount}) {
  final words = wordCount <= 0 ? 1 : wordCount;
  return (errorCount / words * 4).clamp(0.0, 1.0);
}

/// The record of how a free answer was graded, stored JSON-encoded in
/// `activity_attempts.criteriaScores` so the answer review and a later
/// reader can see which signals were present. [parts] are the per-group
/// entailment probabilities when the inference model read the answer (ADR
/// 0014). [explanationEn] and [explanationAr] are the feedback shown to the
/// learner — never read by mastery.
String criteriaScoresJson(
  GradingSignals signals, {
  required double finalScore,
  List<double>? parts,
  String? explanationEn,
  String? explanationAr,
}) {
  final map = <String, Object?>{
    'rubric': signals.rubric,
    if (signals.meaning != null) 'meaning': signals.meaning,
    'parts': ?parts,
    if (signals.grammarPenalty != null) 'grammar': signals.grammarPenalty,
    if (signals.meaningOk != null) 'judgement': signals.meaningOk,
    if (signals.pack != null) 'pack': signals.pack,
    'final': finalScore,
    if (explanationEn != null && explanationEn.isNotEmpty)
      'explanationEn': explanationEn,
    if (explanationAr != null && explanationAr.isNotEmpty)
      'explanationAr': explanationAr,
  };
  return jsonEncode(map);
}

/// The explanation stored in a `criteriaScores` JSON string, or `null` when
/// the string is absent, not JSON, or carries none — every attempt written
/// before ADR 0013, and every attempt graded with nothing to explain, reads
/// as "no explanation" rather than failing.
({String? en, String? ar})? explanationIn(String? criteriaScores) {
  if (criteriaScores == null) return null;
  try {
    final decoded = jsonDecode(criteriaScores);
    if (decoded is! Map) return null;
    final en = decoded['explanationEn'];
    final ar = decoded['explanationAr'];
    if (en is! String && ar is! String) return null;
    return (en: en is String ? en : null, ar: ar is String ? ar : null);
  } on FormatException {
    return null;
  }
}
