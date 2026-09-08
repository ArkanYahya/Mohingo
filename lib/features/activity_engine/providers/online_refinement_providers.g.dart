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
