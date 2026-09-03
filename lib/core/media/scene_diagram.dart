import 'package:flutter/material.dart';

import '../../content/models/media_specification.dart';

/// Renders one of the curriculum bundle's 7 structured scene-media types as
/// a small in-app diagram — these are scene *descriptions* in the bundle,
/// not artwork, so there is nothing to load as an image. See
/// docs/DATA_MODEL.md and docs/ARCHITECTURE.md.
///
/// Node/element order is deliberately never mirrored for RTL — these read
/// closer to a family-tree/floor-plan than a directional icon, so flipping
/// them would be arbitrary rather than meaningful. Only the surrounding
/// chrome mirrors. See docs/ARCHITECTURE.md's risk notes.
///
/// A representative renderer per docs/ARCHITECTURE.md's Phase 5 scope, not
/// a final visual-design pass (flagged as needing one before this ships) —
/// grouped into 4 families by shared shape rather than 7 bespoke widgets:
/// people/relationship diagrams ([peopleCard]/[peopleMap]), room plans
/// ([homePlan]/[apartmentPlan]), object-relation scenes
/// ([objectScene]/[distanceScene]), and single-person descriptors
/// ([personCard]).
class SceneDiagram extends StatelessWidget {
  const SceneDiagram({required this.spec, super.key});

  final MediaSpecification spec;

  @override
  Widget build(BuildContext context) {
    final render = spec.raw['render'] as Map<String, dynamic>? ?? const {};
    return switch (spec.type) {
      'peopleCard' || 'peopleMap' => _PeopleDiagram(render: render),
      'homePlan' || 'apartmentPlan' => _RoomPlanDiagram(render: render),
      'objectScene' ||
      'distanceScene' => _ObjectRelationDiagram(render: render),
      'personCard' => _PersonDescriptor(render: render),
      _ => _UnknownScene(alt: spec.raw['alt'] as String?),
    };
  }
}

class _Chip extends StatelessWidget {
  const _Chip(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: colorScheme.secondaryContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        textDirection: TextDirection.ltr,
        style: Theme.of(context).textTheme.labelSmall
            ?.copyWith(color: colorScheme.onSecondaryContainer),
      ),
    );
  }
}

/// `peopleCard` (`{people: [{id, role}], links: [[id,id,relation]]}`) and
/// `peopleMap` (`{people: [{name, relation, age?}], links: [[name,name,relation]]}`)
/// — both a set of people plus labelled relationship links between them.
class _PeopleDiagram extends StatelessWidget {
  const _PeopleDiagram({required this.render});

  final Map<String, dynamic> render;

  @override
  Widget build(BuildContext context) {
    final people = (render['people'] as List? ?? const [])
        .cast<Map<String, dynamic>>();
    final links = (render['links'] as List? ?? const [])
        .map((l) => List<String>.from(l as List))
        .toList();

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Wrap(
          spacing: 6,
          runSpacing: 6,
          alignment: WrapAlignment.center,
          children: [
            for (final person in people)
              _Chip(
                (person['name'] ?? person['role'] ?? person['id'] ?? '?')
                    .toString(),
              ),
          ],
        ),
        if (links.isNotEmpty) ...[
          const SizedBox(height: 4),
          for (final link in links)
            if (link.length >= 3)
              Text(
                '${link[0]} ↔ ${link[1]}: ${link[2]}',
                textDirection: TextDirection.ltr,
                style: Theme.of(context).textTheme.labelSmall,
                textAlign: TextAlign.center,
              ),
        ],
      ],
    );
  }
}

/// `homePlan` (`{rooms: [string], garden: bool}`) and `apartmentPlan`
/// (`{rooms: [string], adjacency: [...], garden: bool}`).
class _RoomPlanDiagram extends StatelessWidget {
  const _RoomPlanDiagram({required this.render});

  final Map<String, dynamic> render;

  @override
  Widget build(BuildContext context) {
    final rooms = List<String>.from(render['rooms'] as List? ?? const []);
    final hasGarden = render['garden'] as bool? ?? false;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Wrap(
          spacing: 6,
          runSpacing: 6,
          alignment: WrapAlignment.center,
          children: [
            for (final room in rooms) _Chip(room),
            _Chip(hasGarden ? 'garden' : 'no garden'),
          ],
        ),
      ],
    );
  }
}

/// `objectScene` (`{objects: [{id, relation, target}]}`) and
/// `distanceScene` (`{objects: [{id, number, distance}]}`).
class _ObjectRelationDiagram extends StatelessWidget {
  const _ObjectRelationDiagram({required this.render});

  final Map<String, dynamic> render;

  @override
  Widget build(BuildContext context) {
    final objects = (render['objects'] as List? ?? const [])
        .cast<Map<String, dynamic>>();

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final object in objects)
          Text(
            [
              object['id'],
              if (object['relation'] != null)
                '${object['relation']} ${object['target']}',
              if (object['distance'] != null)
                '(${object['number'] ?? ''} ${object['distance']})'.trim(),
            ].where((s) => s != null && s.toString().isNotEmpty).join(' '),
            textDirection: TextDirection.ltr,
            style: Theme.of(context).textTheme.labelSmall,
            textAlign: TextAlign.center,
          ),
      ],
    );
  }
}

/// `personCard` (`{gender, height, action}` or similar free-form attribute
/// set) — rendered as attribute chips since the exact key set varies.
class _PersonDescriptor extends StatelessWidget {
  const _PersonDescriptor({required this.render});

  final Map<String, dynamic> render;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      alignment: WrapAlignment.center,
      children: [
        for (final entry in render.entries) _Chip(entry.value.toString()),
      ],
    );
  }
}

class _UnknownScene extends StatelessWidget {
  const _UnknownScene({this.alt});

  final String? alt;

  @override
  Widget build(BuildContext context) {
    return Icon(
      Icons.image_not_supported_outlined,
      color: Theme.of(context).colorScheme.onSurfaceVariant,
      semanticLabel: alt,
    );
  }
}
