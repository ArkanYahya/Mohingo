// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'level_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Ensures the learner has an enrolment row for [levelId] once its content
/// is loaded. Idempotent — see `LearnerRepository.ensureEnrolled`.

@ProviderFor(ensureLevelEnrolment)
final ensureLevelEnrolmentProvider = EnsureLevelEnrolmentFamily._();

/// Ensures the learner has an enrolment row for [levelId] once its content
/// is loaded. Idempotent — see `LearnerRepository.ensureEnrolled`.

final class EnsureLevelEnrolmentProvider
    extends $FunctionalProvider<AsyncValue<void>, void, FutureOr<void>>
    with $FutureModifier<void>, $FutureProvider<void> {
  /// Ensures the learner has an enrolment row for [levelId] once its content
  /// is loaded. Idempotent — see `LearnerRepository.ensureEnrolled`.
  EnsureLevelEnrolmentProvider._({
    required EnsureLevelEnrolmentFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'ensureLevelEnrolmentProvider',
         isAutoDispose: false,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$ensureLevelEnrolmentHash();

  @override
  String toString() {
    return r'ensureLevelEnrolmentProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<void> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<void> create(Ref ref) {
    final argument = this.argument as String;
    return ensureLevelEnrolment(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is EnsureLevelEnrolmentProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$ensureLevelEnrolmentHash() =>
    r'e25fd217e42a4ef579dd00d847c366dfce5c0d3c';

/// Ensures the learner has an enrolment row for [levelId] once its content
/// is loaded. Idempotent — see `LearnerRepository.ensureEnrolled`.

final class EnsureLevelEnrolmentFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<void>, String> {
  EnsureLevelEnrolmentFamily._()
    : super(
        retry: null,
        name: r'ensureLevelEnrolmentProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: false,
      );

  /// Ensures the learner has an enrolment row for [levelId] once its content
  /// is loaded. Idempotent — see `LearnerRepository.ensureEnrolled`.

  EnsureLevelEnrolmentProvider call(String levelId) =>
      EnsureLevelEnrolmentProvider._(argument: levelId, from: this);

  @override
  String toString() => r'ensureLevelEnrolmentProvider';
}

/// The level the learner is working in — see [currentLevelIdFor]. Every
/// screen that shows "a level" follows this rather than naming one.

@ProviderFor(currentLevelId)
final currentLevelIdProvider = CurrentLevelIdProvider._();

/// The level the learner is working in — see [currentLevelIdFor]. Every
/// screen that shows "a level" follows this rather than naming one.

final class CurrentLevelIdProvider
    extends $FunctionalProvider<AsyncValue<String>, String, FutureOr<String>>
    with $FutureModifier<String>, $FutureProvider<String> {
  /// The level the learner is working in — see [currentLevelIdFor]. Every
  /// screen that shows "a level" follows this rather than naming one.
  CurrentLevelIdProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'currentLevelIdProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$currentLevelIdHash();

  @$internal
  @override
  $FutureProviderElement<String> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<String> create(Ref ref) {
    return currentLevelId(ref);
  }
}

String _$currentLevelIdHash() => r'7ada187cb7b7194feff4c1c2afaed91c682ca2e5';

/// Whether [levelId] is open for the learner right now, and if not, why.

@ProviderFor(levelAccess)
final levelAccessProvider = LevelAccessFamily._();

/// Whether [levelId] is open for the learner right now, and if not, why.

final class LevelAccessProvider
    extends
        $FunctionalProvider<
          AsyncValue<LevelAccess>,
          LevelAccess,
          FutureOr<LevelAccess>
        >
    with $FutureModifier<LevelAccess>, $FutureProvider<LevelAccess> {
  /// Whether [levelId] is open for the learner right now, and if not, why.
  LevelAccessProvider._({
    required LevelAccessFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'levelAccessProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$levelAccessHash();

  @override
  String toString() {
    return r'levelAccessProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<LevelAccess> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<LevelAccess> create(Ref ref) {
    final argument = this.argument as String;
    return levelAccess(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is LevelAccessProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$levelAccessHash() => r'd039df822705bd30385309c4d8a1185ec78ffaca';

/// Whether [levelId] is open for the learner right now, and if not, why.

final class LevelAccessFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<LevelAccess>, String> {
  LevelAccessFamily._()
    : super(
        retry: null,
        name: r'levelAccessProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Whether [levelId] is open for the learner right now, and if not, why.

  LevelAccessProvider call(String levelId) =>
      LevelAccessProvider._(argument: levelId, from: this);

  @override
  String toString() => r'levelAccessProvider';
}

/// Switching levels and opening a locked one — the two writes behind the
/// Learn tab's level strip and its lock sheet.
///
/// `keepAlive`: without it, a caller that only ever does
/// `ref.read(levelSelectionControllerProvider.notifier).select(...)` holds no
/// listener on the controller itself, so plain `@riverpod`'s auto-dispose
/// tears it down — `ref` included — the moment the synchronous part of that
/// read returns, which is *before* `select`/`unlock`'s own `await`s finish
/// (verified: it throws "Cannot use the Ref ... after it has been disposed"
/// partway through `select`). Nothing here is per-argument state that ought
/// to be discarded, so staying alive for the app's life costs nothing.

@ProviderFor(LevelSelectionController)
final levelSelectionControllerProvider = LevelSelectionControllerProvider._();

/// Switching levels and opening a locked one — the two writes behind the
/// Learn tab's level strip and its lock sheet.
///
/// `keepAlive`: without it, a caller that only ever does
/// `ref.read(levelSelectionControllerProvider.notifier).select(...)` holds no
/// listener on the controller itself, so plain `@riverpod`'s auto-dispose
/// tears it down — `ref` included — the moment the synchronous part of that
/// read returns, which is *before* `select`/`unlock`'s own `await`s finish
/// (verified: it throws "Cannot use the Ref ... after it has been disposed"
/// partway through `select`). Nothing here is per-argument state that ought
/// to be discarded, so staying alive for the app's life costs nothing.
final class LevelSelectionControllerProvider
    extends $NotifierProvider<LevelSelectionController, void> {
  /// Switching levels and opening a locked one — the two writes behind the
  /// Learn tab's level strip and its lock sheet.
  ///
  /// `keepAlive`: without it, a caller that only ever does
  /// `ref.read(levelSelectionControllerProvider.notifier).select(...)` holds no
  /// listener on the controller itself, so plain `@riverpod`'s auto-dispose
  /// tears it down — `ref` included — the moment the synchronous part of that
  /// read returns, which is *before* `select`/`unlock`'s own `await`s finish
  /// (verified: it throws "Cannot use the Ref ... after it has been disposed"
  /// partway through `select`). Nothing here is per-argument state that ought
  /// to be discarded, so staying alive for the app's life costs nothing.
  LevelSelectionControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'levelSelectionControllerProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$levelSelectionControllerHash();

  @$internal
  @override
  LevelSelectionController create() => LevelSelectionController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(void value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<void>(value),
    );
  }
}

String _$levelSelectionControllerHash() =>
    r'b5134e25d8a3cbb826131b1009b48e1ed4a15e73';

/// Switching levels and opening a locked one — the two writes behind the
/// Learn tab's level strip and its lock sheet.
///
/// `keepAlive`: without it, a caller that only ever does
/// `ref.read(levelSelectionControllerProvider.notifier).select(...)` holds no
/// listener on the controller itself, so plain `@riverpod`'s auto-dispose
/// tears it down — `ref` included — the moment the synchronous part of that
/// read returns, which is *before* `select`/`unlock`'s own `await`s finish
/// (verified: it throws "Cannot use the Ref ... after it has been disposed"
/// partway through `select`). Nothing here is per-argument state that ought
/// to be discarded, so staying alive for the app's life costs nothing.

abstract class _$LevelSelectionController extends $Notifier<void> {
  void build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<void, void>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<void, void>,
              void,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
