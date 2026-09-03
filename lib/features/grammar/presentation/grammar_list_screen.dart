import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../content/providers/course_content_providers.dart';
import '../../../core/l10n/generated/app_localizations.dart';

/// Browses the A1 grammar registry — searchable by form/Arabic meaning,
/// filterable by the unit that introduced it (the closest available
/// structure to "topic" in the real data). See docs/ARCHITECTURE.md.
class GrammarListScreen extends ConsumerStatefulWidget {
  const GrammarListScreen({super.key});

  @override
  ConsumerState<GrammarListScreen> createState() => _GrammarListScreenState();
}

class _GrammarListScreenState extends ConsumerState<GrammarListScreen> {
  final _searchController = TextEditingController();
  String? _unitFilter;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final contentAsync = ref.watch(courseContentProvider('a1'));

    return Scaffold(
      appBar: AppBar(title: Text(l10n.grammarSectionTitle)),
      body: contentAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('$error')),
        data: (index) {
          final query = _searchController.text.trim().toLowerCase();
          final items = index.bundle.grammar.where((g) {
            if (query.isNotEmpty &&
                !g.form.toLowerCase().contains(query) &&
                !g.meaningAr.contains(_searchController.text.trim())) {
              return false;
            }
            if (_unitFilter != null &&
                index.unitIdByLessonId[g.introducedIn] != _unitFilter) {
              return false;
            }
            return true;
          }).toList();

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: l10n.vocabularySearchHint,
                        prefixIcon: const Icon(Icons.search),
                        border: const OutlineInputBorder(),
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 40,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        children: [
                          ChoiceChip(
                            label: Text(l10n.grammarFilterAllUnits),
                            selected: _unitFilter == null,
                            onSelected: (_) =>
                                setState(() => _unitFilter = null),
                          ),
                          const SizedBox(width: 8),
                          for (final unit in index.bundle.units)
                            Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: ChoiceChip(
                                label: Text(unit.id),
                                selected: _unitFilter == unit.id,
                                onSelected: (_) =>
                                    setState(() => _unitFilter = unit.id),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: items.isEmpty
                    ? Center(child: Text(l10n.vocabularyEmptyResults))
                    : ListView.builder(
                        itemCount: items.length,
                        itemBuilder: (context, i) {
                          final item = items[i];
                          return ListTile(
                            title: Text(
                              item.form,
                              textDirection: TextDirection.ltr,
                            ),
                            subtitle: Text(
                              item.meaningAr,
                              textDirection: TextDirection.rtl,
                            ),
                            onTap: () =>
                                context.push('/review/grammar/${item.id}'),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}
