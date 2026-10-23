/// The candidate models the spike can download, chosen per ADR 0013
/// (decision 4: a 1-2 billion-parameter instruction model at 4-bit). Every
/// file is a GGUF on Hugging Face in a repository that needs no login; the
/// sizes are the ones the file pages show (2026-10-23).
///
/// The owner adds a model by URL from the app, so a wrong or moved file here
/// never blocks the spike.
class CandidateModel {
  const CandidateModel({
    required this.id,
    required this.name,
    required this.uri,
    required this.approxMb,
    required this.license,
    required this.note,
    this.disableThinking = false,
    this.heavy = false,
  });

  /// Short stable id, used in the report.
  final String id;
  final String name;

  /// `hf://owner/repo/file.gguf` or an `https://` URL.
  final String uri;
  final int approxMb;
  final String license;

  /// Why it is a candidate, in a line.
  final String note;

  /// Models with a thinking mode (Qwen3) are asked not to think: a grade
  /// needs no chain of thought and the phone has no time for one.
  final bool disableThinking;

  /// Expected not to fit the reference phone (4 GB); shown with a warning.
  final bool heavy;

  /// `<id>-<file name>`: what the main app would record as the pack version.
  String get packLabel => '$id-${uri.split('/').last}';
}

const List<CandidateModel> kCandidates = [
  CandidateModel(
    id: 'smollm2-135m',
    name: 'SmolLM2 135M Instruct (Q8_0)',
    uri: 'hf://lmstudio-community/SmolLM2-135M-Instruct-GGUF/SmolLM2-135M-Instruct-Q8_0.gguf',
    approxMb: 145,
    license: 'Apache-2.0',
    note:
        'Pipeline check only: tiny, fast, too weak to grade. Run it first to '
        'prove download, load and JSON output work on this phone.',
  ),
  CandidateModel(
    id: 'gemma-3-1b',
    name: 'Gemma 3 1B it (Q4_K_M)',
    uri: 'hf://unsloth/gemma-3-1b-it-GGUF/gemma-3-1b-it-Q4_K_M.gguf',
    approxMb: 806,
    license: 'Gemma Terms of Use',
    note:
        'Smallest serious candidate; trained on 140 languages, Arabic '
        'included, so the Arabic explanation has a chance.',
  ),
  CandidateModel(
    id: 'llama-3.2-1b',
    name: 'Llama 3.2 1B Instruct (Q4_K_M)',
    uri: 'hf://unsloth/Llama-3.2-1B-Instruct-GGUF/Llama-3.2-1B-Instruct-Q4_K_M.gguf',
    approxMb: 808,
    license: 'Llama 3.2 Community License',
    note:
        'Strong English judge for its size; Arabic is not among its eight '
        'official languages, so expect a weak Arabic explanation.',
  ),
  CandidateModel(
    id: 'qwen2.5-1.5b',
    name: 'Qwen2.5 1.5B Instruct (Q4_K_M)',
    uri: 'hf://Qwen/Qwen2.5-1.5B-Instruct-GGUF/qwen2.5-1.5b-instruct-q4_k_m.gguf',
    approxMb: 1120,
    license: 'Apache-2.0',
    note:
        'The ADR\'s named candidate: best instruction following of the '
        '1-2B class, Arabic among its 29 languages. Apache licence, so it '
        'can be hosted on the project\'s own storage without terms.',
  ),
  CandidateModel(
    id: 'qwen3-1.7b',
    name: 'Qwen3 1.7B (Q4_K_M, thinking off)',
    uri: 'hf://unsloth/Qwen3-1.7B-GGUF/Qwen3-1.7B-Q4_K_M.gguf',
    approxMb: 1110,
    license: 'Apache-2.0',
    note:
        'Newer than Qwen2.5 with 119 languages; its thinking mode is '
        'switched off for grading.',
    disableThinking: true,
  ),
  CandidateModel(
    id: 'gemma-3n-e2b',
    name: 'Gemma 3n E2B it (Q4_K_M)',
    uri: 'hf://unsloth/gemma-3n-E2B-it-GGUF/gemma-3n-E2B-it-Q4_K_M.gguf',
    approxMb: 3030,
    license: 'Gemma Terms of Use',
    note:
        'The ADR\'s other named candidate. 3 GB on disk and more in memory: '
        'expected to fail on a 4 GB phone; try it last, on Wi-Fi.',
    heavy: true,
  ),
];

/// A model the owner typed in by URL.
CandidateModel customCandidate(String uri) => CandidateModel(
  id: 'custom',
  name: 'Custom: ${uri.split('/').last}',
  uri: uri.trim(),
  approxMb: 0,
  license: 'see the model page',
  note: 'Entered by hand.',
);
