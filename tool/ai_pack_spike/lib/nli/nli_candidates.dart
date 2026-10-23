/// Natural-language-inference cross-encoders the spike can download: BERT
/// family only (the spike's tokenizer is WordPiece), with ONNX weights in
/// the Transformers.js layout (`onnx/model_quantized.onnx`, `vocab.txt`,
/// `config.json`), in repositories that need no login.
class NliCandidate {
  const NliCandidate({
    required this.id,
    required this.name,
    required this.repo,
    required this.approxMb,
    required this.note,
  });

  final String id;
  final String name;

  /// `owner/repo` on Hugging Face.
  final String repo;
  final int approxMb;
  final String note;

  /// The files, in download order; the model has a fallback when the
  /// quantized file is absent.
  static const String modelFile = 'onnx/model_quantized.onnx';
  static const String modelFallbackFile = 'onnx/model.onnx';
  static const String vocabFile = 'vocab.txt';
  static const String configFile = 'config.json';

  Uri url(String file) =>
      Uri.parse('https://huggingface.co/$repo/resolve/main/$file');
}

const List<NliCandidate> kNliCandidates = [
  NliCandidate(
    id: 'mobilebert-mnli',
    name: 'MobileBERT uncased MNLI (int8)',
    repo: 'Xenova/mobilebert-uncased-mnli',
    approxMb: 25,
    note:
        'typeform\'s MobileBERT fine-tuned on MNLI (~84% matched accuracy), '
        '25M parameters, built for phones. The Transformers.js zero-shot '
        'example model.',
  ),
  NliCandidate(
    id: 'distilbert-mnli',
    name: 'DistilBERT uncased MNLI (int8)',
    repo: 'Xenova/distilbert-base-uncased-mnli',
    approxMb: 67,
    note:
        'typeform\'s DistilBERT fine-tuned on MNLI (~82% matched accuracy), '
        '67M parameters; no segment ids (a two-input model).',
  ),
];

NliCandidate customNliCandidate(String repo) => NliCandidate(
  id: 'custom',
  name: 'Custom: ${repo.trim()}',
  repo: repo.trim(),
  approxMb: 0,
  note: 'Entered by hand; must have the Transformers.js file layout.',
);
