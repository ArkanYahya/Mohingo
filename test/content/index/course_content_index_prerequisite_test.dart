import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:mohingo/content/index/course_content_index.dart';
import 'package:mohingo/content/models/exceptions.dart';
import 'package:mohingo/content/parsing/course_bundle_parser.dart';

import '../fixtures/minimal_bundle.dart';

CourseContentIndex _index(
  Map<String, dynamic> json, {
  CourseContentIndex? prerequisite,
}) => CourseContentIndex.build(
  CourseBundleParser.parse(jsonEncode(json)),
  prerequisite: prerequisite,
);

void main() {
  final a1 = _index(
    minimalBundleJson(
      level: 'A1',
      grammar: [grammarRecord('A1.G.BE.I_AM')],
      lexicon: [lexiconRecord('A1.LEX.HOME.N01')],
      chunks: [chunkRecord('A1.CHUNK.GOOD_MORNING')],
    ),
  );

  Map<String, dynamic> a2Reviewing() => minimalBundleJson(
    level: 'A2',
    grammar: [grammarRecord('A2.G.BE_PAST')],
    lessonGrammar: ['A2.G.BE_PAST', 'A1.G.BE.I_AM'],
    lessonLexicon: ['A1.LEX.HOME.N01'],
    lessonChunks: ['A1.CHUNK.GOOD_MORNING'],
  );

  test("an A2 lesson may reference A1's grammar, words and phrases through "
      'its prerequisite', () {
    final a2 = _index(a2Reviewing(), prerequisite: a1);

    expect(a2.prerequisite, same(a1));
    expect(a2.resolveGrammar('A1.G.BE.I_AM')!.id, 'A1.G.BE.I_AM');
    expect(a2.resolveLexicon('A1.LEX.HOME.N01')!.id, 'A1.LEX.HOME.N01');
    expect(
      a2.resolveChunk('A1.CHUNK.GOOD_MORNING')!.id,
      'A1.CHUNK.GOOD_MORNING',
    );
  });

  test('its own records come first and stay out of the prerequisite', () {
    final a2 = _index(a2Reviewing(), prerequisite: a1);

    expect(a2.resolveGrammar('A2.G.BE_PAST')!.id, 'A2.G.BE_PAST');
    expect(a2.grammarById.keys, ['A2.G.BE_PAST']);
    expect(a1.resolveGrammar('A2.G.BE_PAST'), isNull);
    expect(a2.resolveGrammar('A1.G.NOT_THERE'), isNull);
  });

  test('without its prerequisite the same references are unresolved', () {
    expect(
      () => _index(a2Reviewing()),
      throwsA(isA<UnresolvedContentReferenceException>()),
    );
  });
}
