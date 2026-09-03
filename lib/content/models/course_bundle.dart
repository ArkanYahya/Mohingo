import 'capstone.dart';
import 'curriculum_structure.dart';
import 'domain_definitions.dart';
import 'media_specification.dart';
import 'registry_items.dart';

/// The bundle's `locale` object: which language is being taught vs. which
/// supports it, and each one's text direction.
class CourseLocale {
  const CourseLocale({
    required this.targetLanguage,
    required this.supportLanguage,
    required this.targetDirection,
    required this.supportDirection,
  });

  factory CourseLocale.fromJson(Map<String, dynamic> json) {
    final direction = json['direction'] as Map<String, dynamic>;
    return CourseLocale(
      targetLanguage: json['targetLanguage'] as String,
      supportLanguage: json['supportLanguage'] as String,
      targetDirection: direction['target'] as String,
      supportDirection: direction['support'] as String,
    );
  }

  final String targetLanguage;
  final String supportLanguage;
  final String targetDirection;
  final String supportDirection;
}

/// The bundle's `course` object — level metadata, not the level catalogue
/// (see `lib/content/catalog`, which is app-owned and level-agnostic).
class CourseMeta {
  const CourseMeta({
    required this.id,
    required this.title,
    required this.titleAr,
    required this.status,
    required this.finalMissionId,
    required this.finalAssessmentId,
  });

  factory CourseMeta.fromJson(Map<String, dynamic> json) {
    return CourseMeta(
      id: json['id'] as String,
      title: json['title'] as String,
      titleAr: json['titleAr'] as String,
      status: json['status'] as String,
      finalMissionId: json['finalMissionId'] as String,
      finalAssessmentId: json['finalAssessmentId'] as String,
    );
  }

  final String id;
  final String title;
  final String titleAr;
  final String status;
  final String finalMissionId;
  final String finalAssessmentId;
}

/// The fully parsed curriculum bundle for one CEFR level — the app's only
/// source of curriculum content. Read-only at runtime; never mutated, never
/// mirrored into Drift (progress data only ever references its stable
/// string ids). See docs/ARCHITECTURE.md and docs/DATA_MODEL.md.
class CourseBundle {
  const CourseBundle({
    required this.schemaVersion,
    required this.contentVersion,
    required this.locale,
    required this.course,
    required this.domain,
    required this.grammar,
    required this.lexicon,
    required this.chunks,
    required this.units,
    required this.mediaSpecifications,
    required this.finalMission,
    required this.finalAssessment,
  });

  factory CourseBundle.fromJson(Map<String, dynamic> json) {
    final mediaJson = json['mediaSpecifications'] as Map<String, dynamic>;
    return CourseBundle(
      schemaVersion: json['schemaVersion'] as String,
      contentVersion: json['contentVersion'] as String,
      locale: CourseLocale.fromJson(json['locale'] as Map<String, dynamic>),
      course: CourseMeta.fromJson(json['course'] as Map<String, dynamic>),
      domain: DomainDefinitions.fromJson(
        json['domain'] as Map<String, dynamic>,
      ),
      grammar: (json['grammar'] as List)
          .map((g) => GrammarItem.fromJson(g as Map<String, dynamic>))
          .toList(),
      lexicon: (json['lexicon'] as List)
          .map((l) => LexiconItem.fromJson(l as Map<String, dynamic>))
          .toList(),
      chunks: (json['chunks'] as List)
          .map((c) => ChunkItem.fromJson(c as Map<String, dynamic>))
          .toList(),
      units: (json['units'] as List)
          .map((u) => Unit.fromJson(u as Map<String, dynamic>))
          .toList(),
      mediaSpecifications: mediaJson.map(
        (key, value) => MapEntry(
          key,
          MediaSpecification.fromJson(value as Map<String, dynamic>),
        ),
      ),
      finalMission: FinalMission.fromJson(
        json['finalMission'] as Map<String, dynamic>,
      ),
      finalAssessment: FinalAssessment.fromJson(
        json['finalAssessment'] as Map<String, dynamic>,
      ),
    );
  }

  final String schemaVersion;
  final String contentVersion;
  final CourseLocale locale;
  final CourseMeta course;
  final DomainDefinitions domain;
  final List<GrammarItem> grammar;
  final List<LexiconItem> lexicon;
  final List<ChunkItem> chunks;
  final List<Unit> units;
  final Map<String, MediaSpecification> mediaSpecifications;
  final FinalMission finalMission;
  final FinalAssessment finalAssessment;
}
