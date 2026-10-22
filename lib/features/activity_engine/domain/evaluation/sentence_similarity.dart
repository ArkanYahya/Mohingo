import 'dart:math' as math;
import 'dart:typed_data';

/// The arithmetic behind the meaning signal, kept pure so it is tested
/// without the model: mean pooling, the cosine, and the two-threshold map
/// from a cosine to a 0..1 signal (ADR 0011).

/// Mean-pools a `[tokens × dim]` row-major `last_hidden_state` into one
/// L2-normalised vector. Every token counts (the attention mask is all ones:
/// one text per run, no padding).
Float32List meanPoolNormalized(List<num> flat, {required int tokens}) {
  if (tokens <= 0 || flat.isEmpty || flat.length % tokens != 0) {
    throw ArgumentError(
      'cannot pool ${flat.length} values over $tokens tokens',
    );
  }
  final dim = flat.length ~/ tokens;
  final out = Float32List(dim);
  for (var t = 0; t < tokens; t++) {
    final base = t * dim;
    for (var d = 0; d < dim; d++) {
      out[d] += flat[base + d].toDouble();
    }
  }
  var norm = 0.0;
  for (var d = 0; d < dim; d++) {
    out[d] /= tokens;
    norm += out[d] * out[d];
  }
  norm = math.sqrt(norm);
  if (norm > 0) {
    for (var d = 0; d < dim; d++) {
      out[d] /= norm;
    }
  }
  return out;
}

/// The dot product of two normalised vectors — their cosine similarity.
double cosine(Float32List a, Float32List b) {
  if (a.length != b.length) {
    throw ArgumentError('vectors of ${a.length} and ${b.length} dimensions');
  }
  var sum = 0.0;
  for (var i = 0; i < a.length; i++) {
    sum += a[i] * b[i];
  }
  return sum;
}

/// Cosine at or below [low] is no meaning signal (0), at or above [high] is
/// a full one (1), linear between. The defaults were set from the shipped
/// model on A1/A2 answers (2026-10-22): unrelated sentences score about 0
/// to 0.25, an echo of the partner's line about 0.5, the same thing said in
/// other words 0.7 to 0.95 — see docs/superpowers/specs/
/// 2026-10-22-on-device-free-answer-grading-design.md.
double meaningFromCosine(
  double similarity, {
  double low = kDefaultLowSimilarity,
  double high = kDefaultHighSimilarity,
}) {
  if (high <= low) throw ArgumentError('high must exceed low');
  return ((similarity - low) / (high - low)).clamp(0.0, 1.0);
}

const double kDefaultLowSimilarity = 0.35;
const double kDefaultHighSimilarity = 0.75;
