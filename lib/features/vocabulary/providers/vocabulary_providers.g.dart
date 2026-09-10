// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'vocabulary_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(vocabularyReviewService)
final vocabularyReviewServiceProvider = VocabularyReviewServiceProvider._();

final class VocabularyReviewServiceProvider
    extends
        $FunctionalProvider<
          VocabularyReviewService,
          VocabularyReviewService,
          VocabularyReviewService
        >
    with $Provider<VocabularyReviewService> {
  VocabularyReviewServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'vocabularyReviewServiceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$vocabularyReviewServiceHash();

  @$internal
  @override
  $ProviderElement<VocabularyReviewService> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  VocabularyReviewService create(Ref ref) {
    return vocabularyReviewService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(VocabularyReviewService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<VocabularyReviewService>(value),
    );
  }
}

String _$vocabularyReviewServiceHash() =>
    r'b5a730662b143d1568337ad4f52586c804b55462';
