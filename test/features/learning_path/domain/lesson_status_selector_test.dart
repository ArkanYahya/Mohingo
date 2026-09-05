import 'package:flutter_test/flutter_test.dart';
import 'package:mohingo/content/models/activity.dart';
import 'package:mohingo/content/models/curriculum_structure.dart';
import 'package:mohingo/content/models/domain_definitions.dart';
import 'package:mohingo/core/widgets/status_indicator.dart';
import 'package:mohingo/data/local/database.dart';
import 'package:mohingo/features/learning_path/domain/lesson_status_selector.dart';

Activity _choiceActivity(String id) => TextChoiceActivity(
  id: id,
  lessonId: 'L1',
  mode: ActivityMode.mastery,
  skill: Skill.reading,
  canDo: const [],
  prompt: 'Pick one.',
  promptAr: 'اختر واحداً.',
  raw: const {},
  options: const ['a', 'b'],
  answer: 'a',
);

Lesson _lesson(List<Activity> activities) => Lesson(
  id: 'L1',
  title: 'L1',
  titleAr: 'L1',
  lessonType: 'focus-practice',
  canDo: const [],
  grammar: const [],
  lexicon: const [],
  chunks: const [],
  encounterDialogue: const [],
  activities: activities,
  raw: const {},
);

LessonProgressData _progressAt(String lastActivityId) => LessonProgressData(
  id: 0,
  uuid: 'p1',
  learnerId: 1,
  lessonId: 'L1',
  unitId: 'U1',
  state: 'inProgress',
  lastActivityId: lastActivityId,
  updatedAt: DateTime.utc(2026, 9, 5),
);

ActivityAttempt _attempt({
  required String activityId,
  required bool? isCorrect,
  required DateTime attemptedAt,
}) => ActivityAttempt(
  id: 0,
  uuid: '$activityId-${attemptedAt.microsecondsSinceEpoch}',
  learnerId: 1,
  activityId: activityId,
  lessonId: 'L1',
  sessionType: 'lesson',
  mode: 'mastery',
  evidenceSkill: 'reading',
  isCorrect: isCorrect,
  wasFallback: false,
  attemptedAt: attemptedAt,
  updatedAt: attemptedAt,
);

void main() {
  test('no progress row at all is notStarted', () {
    final lesson = _lesson([_choiceActivity('A1')]);
    expect(
      lessonStatus(lesson: lesson, progress: null, lessonAttempts: const []),
      ProgressState.notStarted,
    );
  });

  test(
    'progress exists but hasn\'t reached the final activity is inProgress',
    () {
      final lesson = _lesson([_choiceActivity('A1'), _choiceActivity('A2')]);
      expect(
        lessonStatus(
          lesson: lesson,
          progress: _progressAt('A1'),
          lessonAttempts: const [],
        ),
        ProgressState.inProgress,
      );
    },
  );

  test('finished with every activity correct is mastered — the '
      'reported-correct case', () {
    final lesson = _lesson([_choiceActivity('A1'), _choiceActivity('A2')]);
    expect(
      lessonStatus(
        lesson: lesson,
        progress: _progressAt('A2'),
        lessonAttempts: [
          _attempt(
            activityId: 'A1',
            isCorrect: true,
            attemptedAt: DateTime.utc(2026, 9, 5, 10),
          ),
          _attempt(
            activityId: 'A2',
            isCorrect: true,
            attemptedAt: DateTime.utc(2026, 9, 5, 10, 1),
          ),
        ],
      ),
      ProgressState.mastered,
    );
  });

  test('finished with a wrong answer is needsReview, not mastered — the '
      'reported bug: "2 wrong" still showed the finished icon', () {
    final lesson = _lesson([_choiceActivity('A1'), _choiceActivity('A2')]);
    expect(
      lessonStatus(
        lesson: lesson,
        progress: _progressAt('A2'),
        lessonAttempts: [
          _attempt(
            activityId: 'A1',
            isCorrect: false,
            attemptedAt: DateTime.utc(2026, 9, 5, 10),
          ),
          _attempt(
            activityId: 'A2',
            isCorrect: true,
            attemptedAt: DateTime.utc(2026, 9, 5, 10, 1),
          ),
        ],
      ),
      ProgressState.needsReview,
    );
  });

  test('a since-corrected mistake (replay got it right the second time) is '
      'mastered — only the most recent attempt per activity counts', () {
    final lesson = _lesson([_choiceActivity('A1')]);
    expect(
      lessonStatus(
        lesson: lesson,
        progress: _progressAt('A1'),
        lessonAttempts: [
          _attempt(
            activityId: 'A1',
            isCorrect: false,
            attemptedAt: DateTime.utc(2026, 9, 5, 10),
          ),
          _attempt(
            activityId: 'A1',
            isCorrect: true,
            attemptedAt: DateTime.utc(2026, 9, 5, 11),
          ),
        ],
      ),
      ProgressState.mastered,
    );
  });

  test('a not-auto-graded attempt (writing/speaking pending review) is not '
      'treated as wrong', () {
    final lesson = _lesson([_choiceActivity('A1')]);
    expect(
      lessonStatus(
        lesson: lesson,
        progress: _progressAt('A1'),
        lessonAttempts: [
          _attempt(
            activityId: 'A1',
            isCorrect: null,
            attemptedAt: DateTime.utc(2026, 9, 5, 10),
          ),
        ],
      ),
      ProgressState.mastered,
    );
  });

  test('attempts from a different lesson in the same unit are ignored', () {
    final lesson = _lesson([_choiceActivity('A1')]);
    expect(
      lessonStatus(
        lesson: lesson,
        progress: _progressAt('A1'),
        lessonAttempts: [
          ActivityAttempt(
            id: 0,
            uuid: 'other',
            learnerId: 1,
            activityId: 'A1',
            lessonId: 'L2', // a different lesson's activity, same id by
            // coincidence — must not leak across lessons.
            sessionType: 'lesson',
            mode: 'mastery',
            evidenceSkill: 'reading',
            isCorrect: false,
            wasFallback: false,
            attemptedAt: DateTime.utc(2026, 9, 5, 10),
            updatedAt: DateTime.utc(2026, 9, 5, 10),
          ),
        ],
      ),
      ProgressState.mastered,
    );
  });
}
