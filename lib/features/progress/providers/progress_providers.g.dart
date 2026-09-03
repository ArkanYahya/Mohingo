// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'progress_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Every repository here is bound to its `Drift*` implementation today.
/// Adding a future sync layer means writing a new implementation and
/// changing only these bindings — no caller, and no domain-layer code, needs
/// to change. See docs/ARCHITECTURE.md.

@ProviderFor(learnerRepository)
final learnerRepositoryProvider = LearnerRepositoryProvider._();

/// Every repository here is bound to its `Drift*` implementation today.
/// Adding a future sync layer means writing a new implementation and
/// changing only these bindings — no caller, and no domain-layer code, needs
/// to change. See docs/ARCHITECTURE.md.

final class LearnerRepositoryProvider
    extends
        $FunctionalProvider<
          LearnerRepository,
          LearnerRepository,
          LearnerRepository
        >
    with $Provider<LearnerRepository> {
  /// Every repository here is bound to its `Drift*` implementation today.
  /// Adding a future sync layer means writing a new implementation and
  /// changing only these bindings — no caller, and no domain-layer code, needs
  /// to change. See docs/ARCHITECTURE.md.
  LearnerRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'learnerRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$learnerRepositoryHash();

  @$internal
  @override
  $ProviderElement<LearnerRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  LearnerRepository create(Ref ref) {
    return learnerRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(LearnerRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<LearnerRepository>(value),
    );
  }
}

String _$learnerRepositoryHash() => r'aeb56d77716f442bcea3babda7fb8913117ca770';

@ProviderFor(activityAttemptRepository)
final activityAttemptRepositoryProvider = ActivityAttemptRepositoryProvider._();

final class ActivityAttemptRepositoryProvider
    extends
        $FunctionalProvider<
          ActivityAttemptRepository,
          ActivityAttemptRepository,
          ActivityAttemptRepository
        >
    with $Provider<ActivityAttemptRepository> {
  ActivityAttemptRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'activityAttemptRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$activityAttemptRepositoryHash();

  @$internal
  @override
  $ProviderElement<ActivityAttemptRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  ActivityAttemptRepository create(Ref ref) {
    return activityAttemptRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ActivityAttemptRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ActivityAttemptRepository>(value),
    );
  }
}

String _$activityAttemptRepositoryHash() =>
    r'f21c4d0555ab2d3ece0a986e74f067cf0ea509e4';

@ProviderFor(unitLessonProgressRepository)
final unitLessonProgressRepositoryProvider =
    UnitLessonProgressRepositoryProvider._();

final class UnitLessonProgressRepositoryProvider
    extends
        $FunctionalProvider<
          UnitLessonProgressRepository,
          UnitLessonProgressRepository,
          UnitLessonProgressRepository
        >
    with $Provider<UnitLessonProgressRepository> {
  UnitLessonProgressRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'unitLessonProgressRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$unitLessonProgressRepositoryHash();

  @$internal
  @override
  $ProviderElement<UnitLessonProgressRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  UnitLessonProgressRepository create(Ref ref) {
    return unitLessonProgressRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(UnitLessonProgressRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<UnitLessonProgressRepository>(value),
    );
  }
}

String _$unitLessonProgressRepositoryHash() =>
    r'ac8468f0f88809ff273b40d8a64d0e1bd9c06014';

@ProviderFor(assessmentAttemptRepository)
final assessmentAttemptRepositoryProvider =
    AssessmentAttemptRepositoryProvider._();

final class AssessmentAttemptRepositoryProvider
    extends
        $FunctionalProvider<
          AssessmentAttemptRepository,
          AssessmentAttemptRepository,
          AssessmentAttemptRepository
        >
    with $Provider<AssessmentAttemptRepository> {
  AssessmentAttemptRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'assessmentAttemptRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$assessmentAttemptRepositoryHash();

  @$internal
  @override
  $ProviderElement<AssessmentAttemptRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  AssessmentAttemptRepository create(Ref ref) {
    return assessmentAttemptRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AssessmentAttemptRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AssessmentAttemptRepository>(value),
    );
  }
}

String _$assessmentAttemptRepositoryHash() =>
    r'0c3a80a9e82b17dcd732b3568a6308525db05806';

@ProviderFor(reviewStateRepository)
final reviewStateRepositoryProvider = ReviewStateRepositoryProvider._();

final class ReviewStateRepositoryProvider
    extends
        $FunctionalProvider<
          ReviewStateRepository,
          ReviewStateRepository,
          ReviewStateRepository
        >
    with $Provider<ReviewStateRepository> {
  ReviewStateRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'reviewStateRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$reviewStateRepositoryHash();

  @$internal
  @override
  $ProviderElement<ReviewStateRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  ReviewStateRepository create(Ref ref) {
    return reviewStateRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ReviewStateRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ReviewStateRepository>(value),
    );
  }
}

String _$reviewStateRepositoryHash() =>
    r'6170fb8140dc4d5070510a98c915c3fc0d23101e';

@ProviderFor(contentVersionRepository)
final contentVersionRepositoryProvider = ContentVersionRepositoryProvider._();

final class ContentVersionRepositoryProvider
    extends
        $FunctionalProvider<
          ContentVersionRepository,
          ContentVersionRepository,
          ContentVersionRepository
        >
    with $Provider<ContentVersionRepository> {
  ContentVersionRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'contentVersionRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$contentVersionRepositoryHash();

  @$internal
  @override
  $ProviderElement<ContentVersionRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  ContentVersionRepository create(Ref ref) {
    return contentVersionRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ContentVersionRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ContentVersionRepository>(value),
    );
  }
}

String _$contentVersionRepositoryHash() =>
    r'c7af0ca07caf5ff015cb03e9a330c171ded9a272';

@ProviderFor(masteryAggregationService)
final masteryAggregationServiceProvider = MasteryAggregationServiceProvider._();

final class MasteryAggregationServiceProvider
    extends
        $FunctionalProvider<
          MasteryAggregationService,
          MasteryAggregationService,
          MasteryAggregationService
        >
    with $Provider<MasteryAggregationService> {
  MasteryAggregationServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'masteryAggregationServiceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$masteryAggregationServiceHash();

  @$internal
  @override
  $ProviderElement<MasteryAggregationService> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  MasteryAggregationService create(Ref ref) {
    return masteryAggregationService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(MasteryAggregationService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<MasteryAggregationService>(value),
    );
  }
}

String _$masteryAggregationServiceHash() =>
    r'a4413183c1dcd5e20674a3320addd81e3bc0dcae';
