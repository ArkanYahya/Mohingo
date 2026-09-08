import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mohingo/features/activity_engine/data/language_tool_grammar_check_service.dart';
import 'package:mohingo/features/activity_engine/domain/evaluation/grammar_check_service.dart';

void main() {
  group('LanguageToolGrammarCheckService', () {
    test('counts matches and words from a well-formed response', () async {
      final client = MockClient((request) async {
        expect(request.method, 'POST');
        expect(request.url.toString(), 'https://api.languagetool.org/v2/check');
        expect(request.bodyFields['text'], 'I has two cat.');
        expect(request.bodyFields['language'], 'en-US');
        return http.Response(
          jsonEncode({
            'matches': [
              {'message': 'Did you mean "have"?'},
              {'message': 'Did you mean "cats"?'},
            ],
          }),
          200,
        );
      });
      final service = LanguageToolGrammarCheckService(client: client);

      final result = await service.check('I has two cat.', localeCode: 'en');

      expect(result.errorCount, 2);
      expect(result.wordCount, 4);
    });

    test(
      'a non-200 response throws GrammarCheckUnavailableException',
      () async {
        final client = MockClient((request) async => http.Response('', 503));
        final service = LanguageToolGrammarCheckService(client: client);

        expect(
          () => service.check('text', localeCode: 'en'),
          throwsA(isA<GrammarCheckUnavailableException>()),
        );
      },
    );

    test('a malformed (non-JSON) response throws '
        'GrammarCheckUnavailableException, not a raw crash', () async {
      final client = MockClient(
        (request) async => http.Response('not json', 200),
      );
      final service = LanguageToolGrammarCheckService(client: client);

      expect(
        () => service.check('text', localeCode: 'en'),
        throwsA(isA<GrammarCheckUnavailableException>()),
      );
    });

    test('a 200 response missing the matches field throws '
        'GrammarCheckUnavailableException', () async {
      final client = MockClient((request) async => http.Response('{}', 200));
      final service = LanguageToolGrammarCheckService(client: client);

      expect(
        () => service.check('text', localeCode: 'en'),
        throwsA(isA<GrammarCheckUnavailableException>()),
      );
    });
  });
}
