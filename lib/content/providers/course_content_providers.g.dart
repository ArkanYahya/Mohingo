// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'course_content_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Loads, parses (off the UI isolate), and indexes the curriculum bundle for
/// [levelId]. Kept alive so a level's ~1,200-leaf-record bundle is parsed
/// once, not per screen — see docs/ARCHITECTURE.md's content-loading
/// strategy.
///
/// A [LevelAvailability.comingSoon] or unknown [levelId] fails fast with a
/// [StateError] — callers should check [levelCatalogEntry] before invoking
/// this provider, not rely on it to report unavailability.
///
/// Failures surface as this provider's [AsyncError]: an
/// `UnsupportedContentSchemaException`/`ContentParseException`/
/// `UnresolvedContentReferenceException` (see `lib/content/models/exceptions.dart`)
/// — the app's content-load route gate distinguishes these to route to the
/// "unsupported content" screen rather than crash.

@ProviderFor(courseContent)
final courseContentProvider = CourseContentFamily._();

/// Loads, parses (off the UI isolate), and indexes the curriculum bundle for
/// [levelId]. Kept alive so a level's ~1,200-leaf-record bundle is parsed
/// once, not per screen — see docs/ARCHITECTURE.md's content-loading
/// strategy.
///
/// A [LevelAvailability.comingSoon] or unknown [levelId] fails fast with a
/// [StateError] — callers should check [levelCatalogEntry] before invoking
/// this provider, not rely on it to report unavailability.
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
  /// [levelId]. Kept alive so a level's ~1,200-leaf-record bundle is parsed
  /// once, not per screen — see docs/ARCHITECTURE.md's content-loading
  /// strategy.
  ///
  /// A [LevelAvailability.comingSoon] or unknown [levelId] fails fast with a
  /// [StateError] — callers should check [levelCatalogEntry] before invoking
  /// this provider, not rely on it to report unavailability.
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

String _$courseContentHash() => r'71ef8521b3c5a9800fe0991f230c4ce0caeba3ea';

/// Loads, parses (off the UI isolate), and indexes the curriculum bundle for
/// [levelId]. Kept alive so a level's ~1,200-leaf-record bundle is parsed
/// once, not per screen — see docs/ARCHITECTURE.md's content-loading
/// strategy.
///
/// A [LevelAvailability.comingSoon] or unknown [levelId] fails fast with a
/// [StateError] — callers should check [levelCatalogEntry] before invoking
/// this provider, not rely on it to report unavailability.
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
  /// [levelId]. Kept alive so a level's ~1,200-leaf-record bundle is parsed
  /// once, not per screen — see docs/ARCHITECTURE.md's content-loading
  /// strategy.
  ///
  /// A [LevelAvailability.comingSoon] or unknown [levelId] fails fast with a
  /// [StateError] — callers should check [levelCatalogEntry] before invoking
  /// this provider, not rely on it to report unavailability.
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
