import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:mohingo/features/activity_engine/domain/evaluation/sentence_similarity.dart';

void main() {
  group('meanPoolNormalized', () {
    test('averages the token rows and normalises to unit length', () {
      // Two tokens, three dimensions.
      final v = meanPoolNormalized([1, 0, 0, 0, 2, 0], tokens: 2);
      // mean = (0.5, 1, 0); norm = sqrt(1.25)
      expect(v[0], closeTo(0.5 / 1.118034, 1e-5));
      expect(v[1], closeTo(1 / 1.118034, 1e-5));
      expect(v[2], 0);
      expect(cosine(v, v), closeTo(1, 1e-6));
    });

    test('refuses a buffer that does not divide into the token count', () {
      expect(
        () => meanPoolNormalized([1, 2, 3], tokens: 2),
        throwsArgumentError,
      );
    });

    test('a zero vector stays zero rather than dividing by zero', () {
      final v = meanPoolNormalized([0, 0, 0, 0], tokens: 2);
      expect(v, [0, 0]);
    });
  });

  group('cosine', () {
    test('is 1 for the same direction, 0 for orthogonal, -1 for opposite', () {
      final a = Float32List.fromList([1, 0]);
      final b = Float32List.fromList([0, 1]);
      final c = Float32List.fromList([-1, 0]);
      expect(cosine(a, a), 1);
      expect(cosine(a, b), 0);
      expect(cosine(a, c), -1);
    });
  });

  group('meaningFromCosine', () {
    test('maps the thresholds to 0 and 1 and is linear between', () {
      expect(meaningFromCosine(0.1), 0);
      expect(meaningFromCosine(0.35), 0);
      expect(meaningFromCosine(0.55), closeTo(0.5, 1e-9));
      expect(meaningFromCosine(0.75), 1);
      expect(meaningFromCosine(0.99), 1);
    });

    test('an echo of the partner line earns little, a paraphrase most', () {
      // Measured on the shipped model, 2026-10-22.
      expect(meaningFromCosine(0.57), closeTo(0.55, 1e-9));
      expect(meaningFromCosine(0.71), closeTo(0.9, 1e-9));
      expect(meaningFromCosine(0.25), 0);
    });

    test('refuses thresholds in the wrong order', () {
      expect(
        () => meaningFromCosine(0.5, low: 0.8, high: 0.2),
        throwsArgumentError,
      );
    });
  });
}
