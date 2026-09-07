import 'package:flutter_test/flutter_test.dart';
import 'package:mohingo/content/models/evaluation_spec.dart';

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

    // A recognized `type` whose required fields are missing or the wrong
    // shape is an authoring error in the bundle. It must degrade to `null`
    // (one un-auto-graded activity) rather than throwing: CourseBundleParser
    // wraps parsing in a try/catch that turns any throw into a whole-bundle
    // ContentParseException, which would blank the entire course over a
    // single typo. See docs/superpowers/specs/
    // 2026-09-07-offline-answer-evaluation-design.md.
    group('malformed but recognized types degrade to null, never throw', () {
      test('numericRange with no min or max', () {
        expect(EvaluationSpec.fromJson({'type': 'numericRange'}), isNull);
      });

      test('numericRange missing just one bound', () {
        expect(
          EvaluationSpec.fromJson({'type': 'numericRange', 'min': 1}),
          isNull,
        );
        expect(
          EvaluationSpec.fromJson({'type': 'numericRange', 'max': 120}),
          isNull,
        );
      });

      test('numericRange with wrong-typed bounds', () {
        expect(
          EvaluationSpec.fromJson({
            'type': 'numericRange',
            'min': 'one',
            'max': 120,
          }),
          isNull,
        );
        expect(
          EvaluationSpec.fromJson({
            'type': 'numericRange',
            'min': 1,
            'max': ['120'],
          }),
          isNull,
        );
      });

      test('letterSequence with no reference', () {
        expect(EvaluationSpec.fromJson({'type': 'letterSequence'}), isNull);
      });

      test('letterSequence with a wrong-typed reference', () {
        expect(
          EvaluationSpec.fromJson({'type': 'letterSequence', 'reference': 42}),
          isNull,
        );
        expect(
          EvaluationSpec.fromJson({
            'type': 'letterSequence',
            'reference': ['profileName'],
          }),
          isNull,
        );
      });

      test('keywordChecklist with no requiredGroups', () {
        expect(
          EvaluationSpec.fromJson({
            'type': 'keywordChecklist',
            'minGroupsMatched': 2,
          }),
          isNull,
        );
      });

      test('keywordChecklist with no minGroupsMatched', () {
        expect(
          EvaluationSpec.fromJson({
            'type': 'keywordChecklist',
            'requiredGroups': [
              ['hi'],
            ],
          }),
          isNull,
        );
      });

      test('keywordChecklist with a wrong-typed minGroupsMatched', () {
        expect(
          EvaluationSpec.fromJson({
            'type': 'keywordChecklist',
            'requiredGroups': [
              ['hi'],
            ],
            'minGroupsMatched': '2',
          }),
          isNull,
        );
      });

      test('keywordChecklist whose groups are not lists', () {
        expect(
          EvaluationSpec.fromJson({
            'type': 'keywordChecklist',
            'requiredGroups': ['hi', 'hello'],
            'minGroupsMatched': 1,
          }),
          isNull,
        );
      });

      test('keywordChecklist whose group entries are not strings', () {
        expect(
          EvaluationSpec.fromJson({
            'type': 'keywordChecklist',
            'requiredGroups': [
              ['hi', 7],
            ],
            'minGroupsMatched': 1,
          }),
          isNull,
        );
      });

      test('keywordChecklist with a non-list requiredGroups', () {
        expect(
          EvaluationSpec.fromJson({
            'type': 'keywordChecklist',
            'requiredGroups': 'hi',
            'minGroupsMatched': 1,
          }),
          isNull,
        );
      });
    });
  });
}
