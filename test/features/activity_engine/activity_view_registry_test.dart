import 'package:flutter_test/flutter_test.dart';
import 'package:mohingo/content/models/activity.dart';
import 'package:mohingo/content/models/domain_definitions.dart';
import 'package:mohingo/features/activity_engine/presentation/activity_view_registry.dart';
import 'package:mohingo/features/activity_engine/presentation/views/choice_activity_view.dart';
import 'package:mohingo/features/activity_engine/presentation/views/dialogue_activity_view.dart';
import 'package:mohingo/features/activity_engine/presentation/views/form_activity_view.dart';
import 'package:mohingo/features/activity_engine/presentation/views/gap_activity_view.dart';
import 'package:mohingo/features/activity_engine/presentation/views/match_activity_view.dart';
import 'package:mohingo/features/activity_engine/presentation/views/order_activity_view.dart';
import 'package:mohingo/features/activity_engine/presentation/views/speak_activity_view.dart';
import 'package:mohingo/features/activity_engine/presentation/views/write_activity_view.dart';

const _common = (
  id: 'x',
  lessonId: 'y',
  mode: ActivityMode.practice,
  skill: Skill.reading,
  canDo: <String>[],
  prompt: 'p',
  promptAr: null,
  raw: <String, dynamic>{},
);

void main() {
  test('every one of the 9 declared activity types has a registered view', () {
    final cases = <Activity, Type>{
      AudioChoiceActivity(
        id: _common.id,
        lessonId: _common.lessonId,
        mode: _common.mode,
        skill: _common.skill,
        canDo: _common.canDo,
        prompt: _common.prompt,
        promptAr: _common.promptAr,
        raw: _common.raw,
        options: const ['a'],
        answer: 'a',
      ): ChoiceActivityView,
      TextChoiceActivity(
        id: _common.id,
        lessonId: _common.lessonId,
        mode: _common.mode,
        skill: _common.skill,
        canDo: _common.canDo,
        prompt: _common.prompt,
        promptAr: _common.promptAr,
        raw: _common.raw,
        options: const ['a'],
        answer: 'a',
      ): ChoiceActivityView,
      MatchActivity(
        id: _common.id,
        lessonId: _common.lessonId,
        mode: _common.mode,
        skill: _common.skill,
        canDo: _common.canDo,
        prompt: _common.prompt,
        promptAr: _common.promptAr,
        raw: _common.raw,
        pairs: const [
          ['a', 'b'],
        ],
      ): MatchActivityView,
      OrderActivity(
        id: _common.id,
        lessonId: _common.lessonId,
        mode: _common.mode,
        skill: _common.skill,
        canDo: _common.canDo,
        prompt: _common.prompt,
        promptAr: _common.promptAr,
        raw: _common.raw,
        tokens: const ['a'],
        answer: const ['a'],
      ): OrderActivityView,
      GapActivity(
        id: _common.id,
        lessonId: _common.lessonId,
        mode: _common.mode,
        skill: _common.skill,
        canDo: _common.canDo,
        prompt: _common.prompt,
        promptAr: _common.promptAr,
        raw: _common.raw,
        text: '___',
        options: const ['a'],
        answer: 'a',
      ): GapActivityView,
      FormActivity(
        id: _common.id,
        lessonId: _common.lessonId,
        mode: _common.mode,
        skill: _common.skill,
        canDo: _common.canDo,
        prompt: _common.prompt,
        promptAr: _common.promptAr,
        raw: _common.raw,
        fields: const ['a'],
      ): FormActivityView,
      SpeakActivity(
        id: _common.id,
        lessonId: _common.lessonId,
        mode: _common.mode,
        skill: _common.skill,
        canDo: _common.canDo,
        prompt: _common.prompt,
        promptAr: _common.promptAr,
        raw: _common.raw,
        accepted: const [],
      ): SpeakActivityView,
      WriteActivity(
        id: _common.id,
        lessonId: _common.lessonId,
        mode: _common.mode,
        skill: _common.skill,
        canDo: _common.canDo,
        prompt: _common.prompt,
        promptAr: _common.promptAr,
        raw: _common.raw,
        accepted: const [],
      ): WriteActivityView,
      DialogueActivity(
        id: _common.id,
        lessonId: _common.lessonId,
        mode: _common.mode,
        skill: _common.skill,
        canDo: _common.canDo,
        prompt: _common.prompt,
        promptAr: _common.promptAr,
        raw: _common.raw,
      ): DialogueActivityView,
    };

    for (final entry in cases.entries) {
      final widget = buildActivityView(
        entry.key,
        learnerId: 1,
        onSubmitted: (_) {},
      );
      expect(
        widget.runtimeType,
        entry.value,
        reason: '${entry.key.runtimeType} should build a ${entry.value}',
      );
    }
  });
}
