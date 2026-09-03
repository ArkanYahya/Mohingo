import 'dart:convert';

import '../models/course_bundle.dart';
import '../models/exceptions.dart';

/// Schema versions this build of the app knows how to parse. A bundle
/// declaring any other `schemaVersion` is rejected before any field is
/// touched — see docs/ARCHITECTURE.md's content-loading strategy.
const kSupportedContentSchemaVersions = {'2.0.0'};

/// Parses a raw curriculum bundle JSON string into a typed [CourseBundle].
///
/// Validates [CourseBundle.schemaVersion] first, before touching any other
/// field, so an unsupported or corrupted asset fails gracefully with a typed
/// exception rather than a raw crash. Intended to run off the UI isolate
/// (`Isolate.run`/`compute`) — see docs/ARCHITECTURE.md — since a full A1
/// bundle has roughly 1,200 leaf records.
abstract final class CourseBundleParser {
  static CourseBundle parse(String rawJson) {
    final Map<String, dynamic> json;
    try {
      json = jsonDecode(rawJson) as Map<String, dynamic>;
    } on FormatException catch (e) {
      throw ContentParseException(
        'Curriculum bundle is not valid JSON',
        cause: e,
      );
    }

    final schemaVersion = json['schemaVersion'] as String?;
    if (schemaVersion == null) {
      throw ContentParseException('Curriculum bundle is missing schemaVersion');
    }
    if (!kSupportedContentSchemaVersions.contains(schemaVersion)) {
      throw UnsupportedContentSchemaException(
        'Curriculum bundle schemaVersion "$schemaVersion" is not supported '
        'by this app version (supported: $kSupportedContentSchemaVersions)',
      );
    }

    try {
      return CourseBundle.fromJson(json);
    } on UnsupportedContentSchemaException {
      rethrow;
    } catch (e) {
      throw ContentParseException(
        'Curriculum bundle passed schema-version validation but failed to parse',
        cause: e,
      );
    }
  }
}
