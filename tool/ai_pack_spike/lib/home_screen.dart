import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'benchmark_cases.dart';
import 'candidates.dart';
import 'judge_prompt.dart';
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
          const SizedBox(height: 12),
          Text('Judgement', style: theme.textTheme.titleMedium),
          const SizedBox(height: 4),
          SegmentedButton<JudgeMode>(
            segments: const [
              ButtonSegment(
                value: JudgeMode.fast,
                label: Text('Fast: verdict + 1 line'),
              ),
              ButtonSegment(
                value: JudgeMode.full,
                label: Text('Full: + correction + Arabic'),
              ),
            ],
            selected: {_c.mode},
            onSelectionChanged: _c.busy ? null : (s) => _c.setMode(s.first),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Text('Threads (applies at Load): '),
              DropdownButton<int>(
                value: _c.threads,
                items: const [
                  DropdownMenuItem(value: 0, child: Text('default')),
                  DropdownMenuItem(value: 2, child: Text('2')),
                  DropdownMenuItem(value: 4, child: Text('4')),
                  DropdownMenuItem(value: 6, child: Text('6')),
                  DropdownMenuItem(value: 8, child: Text('8')),
                ],
                onChanged: _c.busy
                    ? null
                    : (v) {
                        if (v != null) _c.setThreads(v);
                      },
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Selected: ${_c.selected.name}',
            style: theme.textTheme.bodyMedium,
          ),
          Text(
            'Loaded: ${_c.loadedModel?.name ?? 'nothing'}'
            '${_c.isLoaded && !_c.selectedIsLoaded ? ' — press Load to switch to the selected model' : ''}',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: _c.isLoaded && !_c.selectedIsLoaded
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
                onPressed:
                    _c.busy || !_c.selectedIsDownloaded || _c.selectedIsLoaded
                    ? null
                    : _c.load,
                icon: const Icon(Icons.memory),
                label: const Text('Load'),
              ),
              FilledButton.icon(
                onPressed: _c.busy || !_c.selectedIsLoaded
                    ? null
                    : _c.runBenchmark,
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
                  child: Text(
                    _c.phase == SpikePhase.running
                        ? 'Report (partial, ${_c.results.length} of '
                              '${kBenchmarkCases.length})'
                        : 'Report',
                    style: theme.textTheme.titleMedium,
                  ),
                ),
                FilledButton.tonalIcon(
                  onPressed: () => _copy(_c.report!, 'Report copied'),
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
          if (_c.report == null && _c.savedReport != null) ...[
            const Divider(height: 24),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Last saved report (from the previous run)',
                    style: theme.textTheme.titleMedium,
                  ),
                ),
                FilledButton.tonalIcon(
                  onPressed: () =>
                      _copy(_c.savedReport!, 'Saved report copied'),
                  icon: const Icon(Icons.copy),
                  label: const Text('Copy saved report'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            SelectableText(
              _c.savedReport!,
              style: theme.textTheme.bodySmall?.copyWith(
                fontFamily: 'monospace',
              ),
            ),
          ],
          const Divider(height: 24),
          Row(
            children: [
              Expanded(child: Text('Log', style: theme.textTheme.titleMedium)),
              OutlinedButton.icon(
                onPressed: _c.log.isEmpty
                    ? null
                    : () => _copy(_c.logText, 'Log copied'),
                icon: const Icon(Icons.copy),
                label: const Text('Copy log'),
              ),
            ],
          ),
          for (final line in _c.log.take(40))
            Text(line, style: theme.textTheme.bodySmall),
        ],
      ),
    );
  }

  Future<void> _copy(String text, String message) async {
    await Clipboard.setData(ClipboardData(text: text));
    if (mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message)));
    }
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
