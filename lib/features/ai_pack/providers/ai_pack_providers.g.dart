// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ai_pack_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The one binding for the AI pack (ADR 0013). Phase A offers none; Phase B
/// swaps this for the implementation that downloads and manages a real
/// pack, and binds `localJudgementServiceProvider` to it.

@ProviderFor(aiPackService)
final aiPackServiceProvider = AiPackServiceProvider._();

/// The one binding for the AI pack (ADR 0013). Phase A offers none; Phase B
/// swaps this for the implementation that downloads and manages a real
/// pack, and binds `localJudgementServiceProvider` to it.

final class AiPackServiceProvider
    extends $FunctionalProvider<AiPackService, AiPackService, AiPackService>
    with $Provider<AiPackService> {
  /// The one binding for the AI pack (ADR 0013). Phase A offers none; Phase B
  /// swaps this for the implementation that downloads and manages a real
  /// pack, and binds `localJudgementServiceProvider` to it.
  AiPackServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'aiPackServiceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$aiPackServiceHash();

  @$internal
  @override
  $ProviderElement<AiPackService> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  AiPackService create(Ref ref) {
    return aiPackService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AiPackService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AiPackService>(value),
    );
  }
}

String _$aiPackServiceHash() => r'b99dd198f5fd395e0d813852a215c6ecfb7a6e37';

/// What Settings shows: the pack's state on this device.

@ProviderFor(aiPackStatus)
final aiPackStatusProvider = AiPackStatusProvider._();

/// What Settings shows: the pack's state on this device.

final class AiPackStatusProvider
    extends
        $FunctionalProvider<
          AsyncValue<AiPackStatus>,
          AiPackStatus,
          Stream<AiPackStatus>
        >
    with $FutureModifier<AiPackStatus>, $StreamProvider<AiPackStatus> {
  /// What Settings shows: the pack's state on this device.
  AiPackStatusProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'aiPackStatusProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$aiPackStatusHash();

  @$internal
  @override
  $StreamProviderElement<AiPackStatus> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<AiPackStatus> create(Ref ref) {
    return aiPackStatus(ref);
  }
}

String _$aiPackStatusHash() => r'9090fd7d170cf3b14a8970c365c0045c8d6bf1fb';
