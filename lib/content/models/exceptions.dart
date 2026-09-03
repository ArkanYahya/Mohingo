/// Thrown when a curriculum bundle's `schemaVersion` isn't one this version
/// of the app knows how to parse. Caught at the content-loading boundary and
/// turned into the app's "unsupported content" screen — never a raw crash.
/// See docs/ARCHITECTURE.md's content-loading strategy.
class UnsupportedContentSchemaException implements Exception {
  UnsupportedContentSchemaException(this.message);

  final String message;

  @override
  String toString() => 'UnsupportedContentSchemaException: $message';
}

/// Thrown when a curriculum bundle fails to parse for a reason other than an
/// unsupported schema version (malformed/truncated JSON, an unexpectedly
/// missing required field). Also routed to the "unsupported content" screen.
class ContentParseException implements Exception {
  ContentParseException(this.message, {this.cause});

  final String message;
  final Object? cause;

  @override
  String toString() =>
      'ContentParseException: $message${cause != null ? ' ($cause)' : ''}';
}

/// Thrown when a curriculum bundle references a stable id (Can-Do objective,
/// grammar/lexicon/chunk registry entry, lesson, unit) that doesn't resolve
/// to an entry actually present in the bundle. Redundant with the curriculum
/// package's own `unresolvedReferencesForbidden` build-time guarantee, but
/// cheap defense-in-depth against a corrupted or stale asset — see
/// docs/ARCHITECTURE.md.
class UnresolvedContentReferenceException implements Exception {
  UnresolvedContentReferenceException(this.message);

  final String message;

  @override
  String toString() => 'UnresolvedContentReferenceException: $message';
}
