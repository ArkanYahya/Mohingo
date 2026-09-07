import 'package:flutter_test/flutter_test.dart';
import 'package:mohingo/features/activity_engine/domain/evaluation/evaluation_spec.dart';

void main() {
  group('EvaluationSpec.fromJson', () {
    test('a legacy opaque string (not yet migrated) parses to null', () {
      expect(EvaluationSpec.fromJson('non-empty-name'), isNull);
    });

    test('a missing evaluation field parses to null', () {
      expect(EvaluationSpec.fromJson(null), isNull);
    });

    test('an unrecognized type parses to null', () {
      expect(EvaluationSpec.fromJson({'type': 'somethingElse'}), isNull);
    });

    test('parses nonEmpty', () {
      final spec = EvaluationSpec.fromJson({'type': 'nonEmpty'});
      expect(spec, isA<NonEmptyEvaluationSpec>());
    });

    test('parses numericRange', () {
      final spec = EvaluationSpec.fromJson({
        'type': 'numericRange',
        'min': 1,
        'max': 120,
      });
      expect(spec, isA<NumericRangeEvaluationSpec>());
      final range = spec as NumericRangeEvaluationSpec;
      expect(range.min, 1.0);
      expect(range.max, 120.0);
    });

    test('parses letterSequence with a profileName reference', () {
      final spec = EvaluationSpec.fromJson({
        'type': 'letterSequence',
        'reference': 'profileName',
      });
      expect(spec, isA<LetterSequenceEvaluationSpec>());
      expect(
        (spec as LetterSequenceEvaluationSpec).reference,
        isA<ProfileNameReference>(),
      );
    });

    test('parses letterSequence with a previousAnswer reference', () {
      final spec = EvaluationSpec.fromJson({
        'type': 'letterSequence',
        'reference': 'previousAnswer:A1-U0-L5-A01',
      });
      final reference =
          (spec as LetterSequenceEvaluationSpec).reference
              as PreviousAnswerReference;
      expect(reference.activityId, 'A1-U0-L5-A01');
    });

    test('parses letterSequence with a literal reference', () {
      final spec = EvaluationSpec.fromJson({
        'type': 'letterSequence',
        'reference': 'Ali',
      });
      final reference =
          (spec as LetterSequenceEvaluationSpec).reference as LiteralReference;
      expect(reference.text, 'Ali');
    });

    test('parses keywordChecklist', () {
      final spec = EvaluationSpec.fromJson({
        'type': 'keywordChecklist',
        'requiredGroups': [
          ['hi', 'hello'],
          ['weekend', 'saturday'],
        ],
        'minGroupsMatched': 2,
      });
      expect(spec, isA<KeywordChecklistEvaluationSpec>());
      final checklist = spec as KeywordChecklistEvaluationSpec;
      expect(checklist.requiredGroups, [
        ['hi', 'hello'],
        ['weekend', 'saturday'],
      ]);
      expect(checklist.minGroupsMatched, 2);
    });
  });
}
