import '../../../content/models/domain_definitions.dart';

/// Sizes of the runs of consecutive activities that share a mode — the
/// lesson player's progress bar draws one group per run, so a typical
/// encounter → practice → mastery lesson reads as three phases.
///
/// Runs follow the lesson's real order: a mode that comes back later starts
/// a new group rather than merging with its earlier one.
List<int> phaseGroupSizes(List<ActivityMode> modes) {
  final sizes = <int>[];
  ActivityMode? previous;
  for (final mode in modes) {
    if (mode == previous) {
      sizes[sizes.length - 1]++;
    } else {
      sizes.add(1);
      previous = mode;
    }
  }
  return sizes;
}
