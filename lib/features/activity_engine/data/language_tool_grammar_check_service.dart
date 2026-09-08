import 'dart:convert';

import 'package:http/http.dart' as http;

import '../domain/evaluation/grammar_check_service.dart';

final _endpoint = Uri.parse('https://api.languagetool.org/v2/check');
final _whitespace = RegExp(r'\s+');

/// Calls the free public LanguageTool API (`api.languagetool.org`) — no API
/// key, no cost, a soft rate limit of roughly 20 requests/minute per IP with
/// no availability guarantee. This is the one narrow, deliberate exception
/// to this app's otherwise fully-offline design — see
/// docs/adr/0005-narrow-network-exception-for-open-ended-grading.md. Never
/// self-hosted in v1; see the design spec's "Open questions".
class LanguageToolGrammarCheckService implements GrammarCheckService {
  LanguageToolGrammarCheckService({http.Client? client})
    : _client = client ?? http.Client();

  final http.Client _client;

  @override
  Future<GrammarCheckResult> check(
    String text, {
    required String localeCode,
  }) async {
    final http.Response response;
    try {
      response = await _client
          .post(
            _endpoint,
            body: {
              'text': text,
              'language': localeCode == 'en' ? 'en-US' : localeCode,
            },
          )
          .timeout(const Duration(seconds: 10));
    } catch (e) {
      throw GrammarCheckUnavailableException('Request failed: $e');
    }

    if (response.statusCode != 200) {
      throw GrammarCheckUnavailableException(
        'LanguageTool returned HTTP ${response.statusCode}',
      );
    }

    final Object? decoded;
    try {
      decoded = jsonDecode(response.body);
    } on FormatException {
      throw const GrammarCheckUnavailableException(
        'Response body was not valid JSON',
      );
    }

    if (decoded is! Map<String, dynamic> || decoded['matches'] is! List) {
      throw const GrammarCheckUnavailableException(
        'Response was missing a matches field',
      );
    }

    final trimmed = text.trim();
    final wordCount = trimmed.isEmpty ? 0 : trimmed.split(_whitespace).length;
    return GrammarCheckResult(
      errorCount: (decoded['matches'] as List).length,
      wordCount: wordCount,
    );
  }
}
