import 'package:flutter/material.dart';

import '../benchmark_cases.dart';
import 'nli_candidates.dart';
import 'nli_controller.dart';

/// The NLI engine's part of the screen: pick a cross-encoder, download,
/// load, run the same 22 answers part by part, copy the report.
class NliSection extends StatefulWidget {
  const NliSection({super.key, required this.controller, required this.copy});

  final NliController controller;
  final Future<void> Function(String text, String message) copy;

  @override
  State<NliSection> createState() => _NliSectionState();
}

class _NliSectionState extends State<NliSection> {
  final TextEditingController _repo = TextEditingController();

  NliController get _n => widget.controller;

  @override
  void dispose() {
    _repo.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'NLI check (ONNX cross-encoder)',
          style: theme.textTheme.titleMedium,
        ),
        Text(
          'No generation: each listed part becomes a statement, and the model '
          'says whether the answer entails it. Verdict and English check are '
          'computed by code.',
          style: theme.textTheme.bodySmall,
        ),
        RadioGroup<String>(
          groupValue: _n.selected.id,
          onChanged: _n.busy
              ? (_) {}
              : (id) {
                  final m = kNliCandidates.where((c) => c.id == id);
                  if (m.isNotEmpty) _n.select(m.first);
                },
          child: Column(
            children: [
              for (final m in kNliCandidates)
                RadioListTile<String>(
                  value: m.id,
                  enabled: !_n.busy,
                  title: Text(
                    '${m.name} · ~${m.approxMb} MB'
                    '${_n.downloaded.contains(m.id) ? ' · downloaded' : ''}',
                  ),
                  subtitle: Text(m.note),
                  dense: true,
                ),
            ],
          ),
        ),
        TextField(
          controller: _repo,
          enabled: !_n.busy,
          decoration: InputDecoration(
            labelText:
                'Custom Hugging Face repo (owner/name, Transformers.js layout)',
            suffixIcon: IconButton(
              icon: const Icon(Icons.check),
              onPressed: _n.busy ? null : () => _n.selectCustom(_repo.text),
            ),
          ),
          onSubmitted: _n.selectCustom,
        ),
        const SizedBox(height: 8),
        Text('Selected: ${_n.selected.name}'),
        Text(
          'Loaded: ${_n.loadedModel?.name ?? 'nothing'}'
          '${_n.isLoaded && !_n.selectedIsLoaded ? ' — press Load to switch' : ''}',
          style: TextStyle(
            color: _n.isLoaded && !_n.selectedIsLoaded
                ? theme.colorScheme.error
                : null,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            FilledButton.icon(
              onPressed: _n.busy || _n.selectedIsDownloaded
                  ? null
                  : _n.download,
              icon: const Icon(Icons.download),
              label: const Text('Download'),
            ),
            FilledButton.icon(
              onPressed:
                  _n.busy || !_n.selectedIsDownloaded || _n.selectedIsLoaded
                  ? null
                  : _n.load,
              icon: const Icon(Icons.memory),
              label: const Text('Load'),
            ),
            FilledButton.icon(
              onPressed: _n.busy || !_n.selectedIsLoaded ? null : _n.run,
              icon: const Icon(Icons.play_arrow),
              label: Text('Run (${kBenchmarkCases.length} answers)'),
            ),
            OutlinedButton.icon(
              onPressed: _n.busy || !_n.isLoaded ? null : _n.unload,
              icon: const Icon(Icons.eject),
              label: const Text('Unload'),
            ),
            OutlinedButton.icon(
              onPressed: _n.busy || !_n.selectedIsDownloaded
                  ? null
                  : _n.deleteDownloaded,
              icon: const Icon(Icons.delete_outline),
              label: const Text('Delete files'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (_n.phase == NliPhase.downloading)
          ListTile(
            leading: const CircularProgressIndicator(),
            title: Text(
              _n.downloadLine.isEmpty ? 'Starting…' : _n.downloadLine,
            ),
          ),
        if (_n.phase == NliPhase.loading)
          const ListTile(
            leading: CircularProgressIndicator(),
            title: Text('Loading the model…'),
          ),
        if (_n.phase == NliPhase.running)
          ListTile(
            leading: const CircularProgressIndicator(),
            title: Text(
              'Checking answer ${_n.caseIndex} of ${kBenchmarkCases.length}…',
            ),
          ),
        if (_n.report != null) ...[
          Row(
            children: [
              Expanded(
                child: Text(
                  _n.phase == NliPhase.running
                      ? 'NLI report (partial)'
                      : 'NLI report',
                  style: theme.textTheme.titleMedium,
                ),
              ),
              FilledButton.tonalIcon(
                onPressed: () => widget.copy(_n.report!, 'NLI report copied'),
                icon: const Icon(Icons.copy),
                label: const Text('Copy NLI report'),
              ),
            ],
          ),
          SelectableText(
            _n.report!,
            style: theme.textTheme.bodySmall?.copyWith(fontFamily: 'monospace'),
          ),
        ],
        if (_n.report == null && _n.savedReport != null) ...[
          Row(
            children: [
              Expanded(
                child: Text(
                  'Last saved NLI report',
                  style: theme.textTheme.titleMedium,
                ),
              ),
              FilledButton.tonalIcon(
                onPressed: () =>
                    widget.copy(_n.savedReport!, 'Saved NLI report copied'),
                icon: const Icon(Icons.copy),
                label: const Text('Copy saved'),
              ),
            ],
          ),
          SelectableText(
            _n.savedReport!,
            style: theme.textTheme.bodySmall?.copyWith(fontFamily: 'monospace'),
          ),
        ],
        if (_n.log.isNotEmpty) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Text('NLI log', style: theme.textTheme.titleMedium),
              ),
              OutlinedButton.icon(
                onPressed: () => widget.copy(_n.logText, 'NLI log copied'),
                icon: const Icon(Icons.copy),
                label: const Text('Copy'),
              ),
            ],
          ),
          for (final line in _n.log.take(12))
            Text(line, style: theme.textTheme.bodySmall),
        ],
      ],
    );
  }
}
