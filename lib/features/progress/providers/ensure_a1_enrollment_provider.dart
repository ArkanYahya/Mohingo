import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../content/providers/course_content_providers.dart';
import 'current_learner_provider.dart';
import 'progress_providers.dart';

part 'ensure_a1_enrollment_provider.g.dart';

/// Ensures the current learner has a `course_enrolments` row for A1 once
/// both the learner profile and the A1 content bundle are ready. Idempotent
/// — see [LearnerRepository.ensureEnrolled].
@Riverpod(keepAlive: true)
Future<void> ensureA1Enrollment(Ref ref) async {
  final learner = await ref.watch(currentLearnerProvider.future);
  final index = await ref.watch(courseContentProvider('a1').future);
  final learnerRepository = ref.watch(learnerRepositoryProvider);
  await learnerRepository.ensureEnrolled(
    learnerId: learner.id,
    courseId: index.bundle.course.id,
    contentVersion: index.bundle.contentVersion,
  );
}
