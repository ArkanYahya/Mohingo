// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'course_content_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The level catalogue ([kLevelCatalog]); overridden in tests.

@ProviderFor(levelCatalog)
final levelCatalogProvider = LevelCatalogProvider._();

/// The level catalogue ([kLevelCatalog]); overridden in tests.

final class LevelCatalogProvider
    extends
        $FunctionalProvider<
          List<LevelCatalogEntry>,
          List<LevelCatalogEntry>,
          List<LevelCatalogEntry>
        >
    with $Provider<List<LevelCatalogEntry>> {
  /// The level catalogue ([kLevelCatalog]); overridden in tests.
  LevelCatalogProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'levelCatalogProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$levelCatalogHash();

  @$internal
  @override
  $ProviderElement<List<LevelCatalogEntry>> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  List<LevelCatalogEntry> create(Ref ref) {
    return levelCatalog(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(List<LevelCatalogEntry> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<List<LevelCatalogEntry>>(value),
    );
  }
}

String _$levelCatalogHash() => r'567def97dd3901ab756d9a9d8c1c11b8c7d3e882';

/// Reads bundle assets; overridden in tests.

@ProviderFor(bundleAssetLoader)
final bundleAssetLoaderProvider = BundleAssetLoaderProvider._();

/// Reads bundle assets; overridden in tests.

final class BundleAssetLoaderProvider
    extends
        $FunctionalProvider<
          BundleAssetLoader,
          BundleAssetLoader,
          BundleAssetLoader
        >
    with $Provider<BundleAssetLoader> {
  /// Reads bundle assets; overridden in tests.
  BundleAssetLoaderProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'bundleAssetLoaderProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$bundleAssetLoaderHash();

  @$internal
  @override
  $ProviderElement<BundleAssetLoader> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  BundleAssetLoader create(Ref ref) {
    return bundleAssetLoader(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(BundleAssetLoader value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<BundleAssetLoader>(value),
    );
  }
}

String _$bundleAssetLoaderHash() => r'94ef46acb9a3644de63f85c93387ca92208bc1f2';

/// Loads, parses (off the UI isolate), and indexes the curriculum bundle for
/// [levelId]. Kept alive so a level's bundle is parsed once, not per screen
/// — see docs/ARCHITECTURE.md's content-loading strategy.
///
/// A level with a `prerequisiteLevelId` (A2 builds on A1) waits for that
/// level's index and is built with it attached, so its lessons can
/// reference the earlier level's grammar, words and phrases.
///
/// A [LevelAvailability.comingSoon] or unknown [levelId] fails fast with a
/// [StateError] — callers should check the catalogue before invoking this
/// provider, not rely on it to report unavailability.
///
/// Failures surface as this provider's [AsyncError]: an
/// `UnsupportedContentSchemaException`/`ContentParseException`/
/// `UnresolvedContentReferenceException` (see `lib/content/models/exceptions.dart`)
/// — the app's content-load route gate distinguishes these to route to the
/// "unsupported content" screen rather than crash.

@ProviderFor(courseContent)
final courseContentProvider = CourseContentFamily._();

/// Loads, parses (off the UI isolate), and indexes the curriculum bundle for
/// [levelId]. Kept alive so a level's bundle is parsed once, not per screen
/// — see docs/ARCHITECTURE.md's content-loading strategy.
///
/// A level with a `prerequisiteLevelId` (A2 builds on A1) waits for that
/// level's index and is built with it attached, so its lessons can
/// reference the earlier level's grammar, words and phrases.
///
/// A [LevelAvailability.comingSoon] or unknown [levelId] fails fast with a
/// [StateError] — callers should check the catalogue before invoking this
/// provider, not rely on it to report unavailability.
///
/// Failures surface as this provider's [AsyncError]: an
/// `UnsupportedContentSchemaException`/`ContentParseException`/
/// `UnresolvedContentReferenceException` (see `lib/content/models/exceptions.dart`)
/// — the app's content-load route gate distinguishes these to route to the
/// "unsupported content" screen rather than crash.

final class CourseContentProvider
    extends
        $FunctionalProvider<
          AsyncValue<CourseContentIndex>,
          CourseContentIndex,
          FutureOr<CourseContentIndex>
        >
    with
        $FutureModifier<CourseContentIndex>,
        $FutureProvider<CourseContentIndex> {
  /// Loads, parses (off the UI isolate), and indexes the curriculum bundle for
  /// [levelId]. Kept alive so a level's bundle is parsed once, not per screen
  /// — see docs/ARCHITECTURE.md's content-loading strategy.
  ///
  /// A level with a `prerequisiteLevelId` (A2 builds on A1) waits for that
  /// level's index and is built with it attached, so its lessons can
  /// reference the earlier level's grammar, words and phrases.
  ///
  /// A [LevelAvailability.comingSoon] or unknown [levelId] fails fast with a
  /// [StateError] — callers should check the catalogue before invoking this
  /// provider, not rely on it to report unavailability.
  ///
  /// Failures surface as this provider's [AsyncError]: an
  /// `UnsupportedContentSchemaException`/`ContentParseException`/
  /// `UnresolvedContentReferenceException` (see `lib/content/models/exceptions.dart`)
  /// — the app's content-load route gate distinguishes these to route to the
  /// "unsupported content" screen rather than crash.
  CourseContentProvider._({
    required CourseContentFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'courseContentProvider',
         isAutoDispose: false,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$courseContentHash();

  @override
  String toString() {
    return r'courseContentProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<CourseContentIndex> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<CourseContentIndex> create(Ref ref) {
    final argument = this.argument as String;
    return courseContent(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is CourseContentProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$courseContentHash() => r'0343e624352f7ce30aec3522c491f20f924d78b9';

/// Loads, parses (off the UI isolate), and indexes the curriculum bundle for
/// [levelId]. Kept alive so a level's bundle is parsed once, not per screen
/// — see docs/ARCHITECTURE.md's content-loading strategy.
///
/// A level with a `prerequisiteLevelId` (A2 builds on A1) waits for that
/// level's index and is built with it attached, so its lessons can
/// reference the earlier level's grammar, words and phrases.
///
/// A [LevelAvailability.comingSoon] or unknown [levelId] fails fast with a
/// [StateError] — callers should check the catalogue before invoking this
/// provider, not rely on it to report unavailability.
///
/// Failures surface as this provider's [AsyncError]: an
/// `UnsupportedContentSchemaException`/`ContentParseException`/
/// `UnresolvedContentReferenceException` (see `lib/content/models/exceptions.dart`)
/// — the app's content-load route gate distinguishes these to route to the
/// "unsupported content" screen rather than crash.

final class CourseContentFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<CourseContentIndex>, String> {
  CourseContentFamily._()
    : super(
        retry: null,
        name: r'courseContentProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: false,
      );

  /// Loads, parses (off the UI isolate), and indexes the curriculum bundle for
  /// [levelId]. Kept alive so a level's bundle is parsed once, not per screen
  /// — see docs/ARCHITECTURE.md's content-loading strategy.
  ///
  /// A level with a `prerequisiteLevelId` (A2 builds on A1) waits for that
  /// level's index and is built with it attached, so its lessons can
  /// reference the earlier level's grammar, words and phrases.
  ///
  /// A [LevelAvailability.comingSoon] or unknown [levelId] fails fast with a
  /// [StateError] — callers should check the catalogue before invoking this
  /// provider, not rely on it to report unavailability.
  ///
  /// Failures surface as this provider's [AsyncError]: an
  /// `UnsupportedContentSchemaException`/`ContentParseException`/
  /// `UnresolvedContentReferenceException` (see `lib/content/models/exceptions.dart`)
  /// — the app's content-load route gate distinguishes these to route to the
  /// "unsupported content" screen rather than crash.

  CourseContentProvider call(String levelId) =>
      CourseContentProvider._(argument: levelId, from: this);

  @override
  String toString() => r'courseContentProvider';
}
