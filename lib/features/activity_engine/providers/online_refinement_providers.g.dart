// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'online_refinement_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Bound to the real device implementation today, same seam pattern as
/// `speech_providers.dart`'s `textToSpeechServiceProvider` — a future
/// alternative implementation swaps in by changing only this binding.

@ProviderFor(connectivityService)
final connectivityServiceProvider = ConnectivityServiceProvider._();

/// Bound to the real device implementation today, same seam pattern as
/// `speech_providers.dart`'s `textToSpeechServiceProvider` — a future
/// alternative implementation swaps in by changing only this binding.

final class ConnectivityServiceProvider
    extends
        $FunctionalProvider<
          ConnectivityService,
          ConnectivityService,
          ConnectivityService
        >
    with $Provider<ConnectivityService> {
  /// Bound to the real device implementation today, same seam pattern as
  /// `speech_providers.dart`'s `textToSpeechServiceProvider` — a future
  /// alternative implementation swaps in by changing only this binding.
  ConnectivityServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'connectivityServiceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$connectivityServiceHash();

  @$internal
  @override
  $ProviderElement<ConnectivityService> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  ConnectivityService create(Ref ref) {
    return connectivityService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ConnectivityService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ConnectivityService>(value),
    );
  }
}

String _$connectivityServiceHash() =>
    r'f4b7196f2c38431baab2a91cc4b4245a5b29c647';

/// Bound to the real LanguageTool-backed implementation today, same seam
/// pattern as [connectivityService] above — a future alternative
/// implementation swaps in by changing only this binding.

@ProviderFor(grammarCheckService)
final grammarCheckServiceProvider = GrammarCheckServiceProvider._();

/// Bound to the real LanguageTool-backed implementation today, same seam
/// pattern as [connectivityService] above — a future alternative
/// implementation swaps in by changing only this binding.

final class GrammarCheckServiceProvider
    extends
        $FunctionalProvider<
          GrammarCheckService,
          GrammarCheckService,
          GrammarCheckService
        >
    with $Provider<GrammarCheckService> {
  /// Bound to the real LanguageTool-backed implementation today, same seam
  /// pattern as [connectivityService] above — a future alternative
  /// implementation swaps in by changing only this binding.
  GrammarCheckServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'grammarCheckServiceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$grammarCheckServiceHash();

  @$internal
  @override
  $ProviderElement<GrammarCheckService> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  GrammarCheckService create(Ref ref) {
    return grammarCheckService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(GrammarCheckService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<GrammarCheckService>(value),
    );
  }
}

String _$grammarCheckServiceHash() =>
    r'0a846684f1fb15ad3a7d85166b8c887d360450a1';

/// ADR 0011's first layer, the on-device meaning signal. Bound to the
/// unavailable implementation until the embedding model is wired
/// (`OnnxMeaningSignalService`); with it the rubric grades alone, exactly as
/// before, so a build without the model behaves as it always has.

@ProviderFor(meaningSignalService)
final meaningSignalServiceProvider = MeaningSignalServiceProvider._();

/// ADR 0011's first layer, the on-device meaning signal. Bound to the
/// unavailable implementation until the embedding model is wired
/// (`OnnxMeaningSignalService`); with it the rubric grades alone, exactly as
/// before, so a build without the model behaves as it always has.

final class MeaningSignalServiceProvider
    extends
        $FunctionalProvider<
          MeaningSignalService,
          MeaningSignalService,
          MeaningSignalService
        >
    with $Provider<MeaningSignalService> {
  /// ADR 0011's first layer, the on-device meaning signal. Bound to the
  /// unavailable implementation until the embedding model is wired
  /// (`OnnxMeaningSignalService`); with it the rubric grades alone, exactly as
  /// before, so a build without the model behaves as it always has.
  MeaningSignalServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'meaningSignalServiceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$meaningSignalServiceHash();

  @$internal
  @override
  $ProviderElement<MeaningSignalService> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  MeaningSignalService create(Ref ref) {
    return meaningSignalService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(MeaningSignalService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<MeaningSignalService>(value),
    );
  }
}

String _$meaningSignalServiceHash() =>
    r'38b90644c5bda46889b4d7fda966fac6acb1fde7';

/// ADR 0011's second layer, the downloadable AI pack. Phase A ships no pack,
/// so this is never available; Phase B swaps the binding for the installed
/// pack's implementation and nothing else changes.

@ProviderFor(localJudgementService)
final localJudgementServiceProvider = LocalJudgementServiceProvider._();

/// ADR 0011's second layer, the downloadable AI pack. Phase A ships no pack,
/// so this is never available; Phase B swaps the binding for the installed
/// pack's implementation and nothing else changes.

final class LocalJudgementServiceProvider
    extends
        $FunctionalProvider<
          LocalJudgementService,
          LocalJudgementService,
          LocalJudgementService
        >
    with $Provider<LocalJudgementService> {
  /// ADR 0011's second layer, the downloadable AI pack. Phase A ships no pack,
  /// so this is never available; Phase B swaps the binding for the installed
  /// pack's implementation and nothing else changes.
  LocalJudgementServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'localJudgementServiceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$localJudgementServiceHash();

  @$internal
  @override
  $ProviderElement<LocalJudgementService> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  LocalJudgementService create(Ref ref) {
    return localJudgementService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(LocalJudgementService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<LocalJudgementService>(value),
    );
  }
}

String _$localJudgementServiceHash() =>
    r'27485eff6856d52fd47889e714b57fba0961ee61';

/// The single [PendingRefinementRepository] binding for v1 — same seam
/// pattern as [connectivityService]/[grammarCheckService] above.

@ProviderFor(pendingRefinementRepository)
final pendingRefinementRepositoryProvider =
    PendingRefinementRepositoryProvider._();

/// The single [PendingRefinementRepository] binding for v1 — same seam
/// pattern as [connectivityService]/[grammarCheckService] above.

final class PendingRefinementRepositoryProvider
    extends
        $FunctionalProvider<
          PendingRefinementRepository,
          PendingRefinementRepository,
          PendingRefinementRepository
        >
    with $Provider<PendingRefinementRepository> {
  /// The single [PendingRefinementRepository] binding for v1 — same seam
  /// pattern as [connectivityService]/[grammarCheckService] above.
  PendingRefinementRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'pendingRefinementRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$pendingRefinementRepositoryHash();

  @$internal
  @override
  $ProviderElement<PendingRefinementRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  PendingRefinementRepository create(Ref ref) {
    return pendingRefinementRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(PendingRefinementRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<PendingRefinementRepository>(value),
    );
  }
}

String _$pendingRefinementRepositoryHash() =>
    r'323e1d5f98dc7da22128513b62880b0a66d34cb3';
