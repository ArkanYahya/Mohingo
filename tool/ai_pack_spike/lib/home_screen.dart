import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'benchmark_cases.dart';
import 'candidates.dart';
import 'spike_controller.dart';

/// One screen: pick a model, download it, load it, run the benchmark, copy
/// the report. Developer tooling, so the copy is English with an Arabic
/// line of directions at the top.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final SpikeController _c = SpikeController();
  final TextEditingController _customUri = TextEditingController();
  final TextEditingController _token = TextEditingController();

  @override
  void initState() {
    super.initState();
    _c.addListener(_onChanged);
    _c.init();
  }

  void _onChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _c.removeListener(_onChanged);
    _c.dispose();
    _customUri.dispose();
    _token.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Mohingo AI-pack spike')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'الخطوات: اختر نموذجاً ← Download ← Load ← Run ← Copy report، '
            'ثم ألصق التقرير في المحادثة.',
            textDirection: TextDirection.rtl,
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 8),
          Text(_c.deviceLine, style: theme.textTheme.bodySmall),
          const Divider(height: 24),
          Text('Model', style: theme.textTheme.titleMedium),
          RadioGroup<String>(
            groupValue: _c.selected.uri,
            onChanged: _c.busy
                ? (_) {}
                : (uri) {
                    final m = kCandidates.where((c) => c.uri == uri);
                    if (m.isNotEmpty) _c.select(m.first);
                  },
            child: Column(
              children: [
                for (final m in kCandidates)
                  RadioListTile<String>(
                    value: m.uri,
                    enabled: !_c.busy,
                    title: Text(
                      '${m.name} · ${m.approxMb} MB'
                      '${_c.downloaded.contains(m.uri) ? ' · downloaded' : ''}',
                    ),
                    subtitle: Text(
                      '${m.note}${m.heavy ? ' ⚠ heavy' : ''} · ${m.license}',
                    ),
                    dense: true,
                  ),
              ],
            ),
          ),
          TextField(
            controller: _customUri,
            enabled: !_c.busy,
            decoration: InputDecoration(
              labelText: 'Custom hf://owner/repo/file.gguf or https:// URL',
              suffixIcon: IconButton(
                icon: const Icon(Icons.check),
                onPressed: _c.busy
                    ? null
                    : () => _c.selectCustom(_customUri.text),
              ),
            ),
            onSubmitted: _c.selectCustom,
          ),
          TextField(
            controller: _token,
            enabled: !_c.busy,
            obscureText: true,
            decoration: const InputDecoration(
              labelText: 'Hugging Face token (only for gated repositories)',
            ),
            onChanged: _c.setToken,
          ),
          const SizedBox(height: 8),
          Text(
            'Selected: ${_c.selected.name}'
            '${_c.isLoaded && _c.loadedUri == _c.selected.uri ? ' (loaded)' : ''}',
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              FilledButton.icon(
                onPressed: _c.busy || _c.selectedIsDownloaded
                    ? null
                    : _c.download,
                icon: const Icon(Icons.download),
                label: const Text('Download'),
              ),
              if (_c.phase == SpikePhase.downloading)
                OutlinedButton(
                  onPressed: _c.cancelDownload,
                  child: const Text('Cancel'),
                ),
              FilledButton.icon(
                onPressed: _c.busy || !_c.selectedIsDownloaded ? null : _c.load,
                icon: const Icon(Icons.memory),
                label: const Text('Load'),
              ),
              FilledButton.icon(
                onPressed: _c.busy || !_c.isLoaded ? null : _c.runBenchmark,
                icon: const Icon(Icons.play_arrow),
                label: Text('Run (${kBenchmarkCases.length} answers)'),
              ),
              OutlinedButton.icon(
                onPressed: _c.busy || !_c.isLoaded ? null : _c.unload,
                icon: const Icon(Icons.eject),
                label: const Text('Unload'),
              ),
              OutlinedButton.icon(
                onPressed: _c.busy || !_c.selectedIsDownloaded
                    ? null
                    : _c.deleteDownloaded,
                icon: const Icon(Icons.delete_outline),
                label: const Text('Delete file'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_c.phase == SpikePhase.downloading) _downloadProgress(theme),
          if (_c.phase == SpikePhase.loading)
            const ListTile(
              leading: CircularProgressIndicator(),
              title: Text('Loading the model into memory…'),
            ),
          if (_c.phase == SpikePhase.running)
            ListTile(
              leading: const CircularProgressIndicator(),
              title: Text(
                'Judging answer ${_c.caseIndex} of ${kBenchmarkCases.length}…',
              ),
            ),
          if (_c.report != null) ...[
            const Divider(height: 24),
            Row(
              children: [
                Expanded(
                  child: Text('Report', style: theme.textTheme.titleMedium),
                ),
                FilledButton.tonalIcon(
                  onPressed: () async {
                    await Clipboard.setData(ClipboardData(text: _c.report!));
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Report copied')),
                      );
                    }
                  },
                  icon: const Icon(Icons.copy),
                  label: const Text('Copy report'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            SelectableText(
              _c.report!,
              style: theme.textTheme.bodySmall?.copyWith(
                fontFamily: 'monospace',
              ),
            ),
          ],
          const Divider(height: 24),
          Text('Log', style: theme.textTheme.titleMedium),
          for (final line in _c.log.take(40))
            Text(line, style: theme.textTheme.bodySmall),
        ],
      ),
    );
  }

  Widget _downloadProgress(ThemeData theme) {
    final s = _c.downloadSnapshot;
    final p = s?.progress;
    final received = p == null ? null : p.receivedBytes / (1024 * 1024);
    final total = p?.totalBytes == null ? null : p!.totalBytes! / (1024 * 1024);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LinearProgressIndicator(value: s?.fraction),
        const SizedBox(height: 4),
        Text(
          '${s?.stage.name ?? 'starting'}'
          '${received == null ? '' : ' · ${received.toStringAsFixed(0)}'
                    '${total == null ? '' : ' / ${total.toStringAsFixed(0)}'} MB'}',
          style: theme.textTheme.bodySmall,
        ),
      ],
    );
  }
}
