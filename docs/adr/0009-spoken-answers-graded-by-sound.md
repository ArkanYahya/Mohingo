# 0009: A spoken answer is graded by what was said, a typed one by what was written

**Status:** Accepted

_Last verified: 2026-09-23 (`feature/learner-feedback-alignment-autoscroll-partner-cues`) — written with the change it records._

## Context

A learner answered A1-U1-L4-A03 ("Introduce Sara as your friend.") aloud. The recogniser returned "this is Sarah she's my friend", and the app marked it wrong. Two things were wrong, one small and one a policy gap.

The small one: that task carries both an `accepted` model answer and a keyword rubric, and the speak and write views graded by the accepted list whenever one existed, never consulting the rubric. Thirteen A1 speaking tasks were graded that way; A2 has no accepted lists.

The policy gap: neither grader knew that a transcript's spelling belongs to the recogniser, not the learner. The recogniser spells names the common way ("Sarah", "Omar", "Maya"), picks a homophone at random ("two"/"to", "four"/"for", "there"/"their"), and returns numbers in digits for one speaker and in words for the next. The learner said the right thing and was failed on the recogniser's choice of letters. The speech plugin exposes no vocabulary hints, so this cannot be corrected at the source; it has to be handled in the grader.

Grading is fully offline and deterministic ([ADR 0003](0003-on-device-speech-writing-assessment-for-mvp.md), [ADR 0005](0005-narrow-network-exception-for-open-ended-grading.md)), and A1 tests exactly the distinctions that sound-alike matching would blur: "bag"/"big", "this"/"these", "he"/"she", "sister"/"mister". Any tolerance has to be narrow enough not to hand those out.

## Decision

1. **The rubric grades; the accepted list is the model answer.** A speak or write task with a structured `evaluation` is graded by it. Its `accepted` list grades only a task that has no rubric, and is otherwise what the feedback panel shows after a miss. A content gate requires that a task's model answer passes its own rubric.

2. **A recognised transcript is graded as it was said; a typed answer as it was written.** The speak view marks a transcript as a `SpokenAnswer`; the typed fallback and the write view never do. Spelling is what a writer practises, so it stays strict for them. For a transcript the grader forgives exactly three things:
   - **Names, by sound.** A transcript word that sounds like one of the task's proper names counts as that name. The task's names are the words it capitalises other than at a sentence start, across its prompt, model answers, partner lines, partner label, transcript and source card — so "Introduce Sara as your friend." names Sara and no plumbing of a level-wide cast is needed. Sound is a Metaphone-style key (`phoneticKey`) that reduces consonants to their classes and drops vowels; it is applied to names only.
   - **Homophones.** A fixed table of common English homophone groups is reduced to one spelling on both sides ("two", "to" and "too" are one word).
   - **Numbers.** Digits in a transcript are compared as the words they are spoken as ("at 7" meets "at seven").

3. **Numbers in words are numbers**, spoken or typed: a `numericRange` rubric reads "twenty-five" as 25.

This lives in `lib/features/activity_engine/domain/spoken_answer.dart`, `spoken_numbers.dart`, `answer_matching.dart` and `evaluation/evaluator.dart`, and applies wherever the speak view is used — lessons, review, placement, Final Mission and Final Assessment.

## Alternatives considered

- **General fuzzy matching (edit distance or phonetic keys on every word).** Rejected: a sound-only comparison cannot tell "bag" from "big" or "this" from "these", which are the very things the level tests; an edit-distance threshold small enough to keep those apart does not reach "there"/"their". Tolerance is kept to names, a closed homophone table and numbers.
- **A hand-maintained table of name spellings in the bundle** ("Sara": ["Sarah"]). Rejected: it fails on the next spelling the recogniser invents and puts a recogniser's habits into the curriculum. Sound-alike matching over the task's own names needs no list.
- **Biasing the recogniser with the expected words.** Not available: `speech_to_text` exposes no contextual vocabulary on either platform.
- **Loosening typed answers the same way.** Rejected: a typed answer's spelling is the learner's, and spelling a name or "their" correctly is part of writing.

## Consequences

- A learner is no longer failed for the recogniser's spelling of a name, a homophone or a number, and the thirteen A1 tasks with both graders are graded by the rubric their author wrote.
- Sound-alike tolerance applies only to a word the task capitalises, so a capitalised common word ("English", "Saturday") is also matched by sound; harmless, since only a word that sounds like it would match. A name the task never writes is not forgiven — an author who puts a name in a rubric must name the person in the prompt.
- The phonetic key is coarse by design (it is why it is restricted to names); two different names that sound alike ("Mia"/"Maya") would pass for each other in a task that names one of them.
- The homophone table is a closed list in code, not content; extending it is a code change with a test.
- `evaluate()` and `answersMatch()` gained a `spoken` parameter; every other grader is unchanged, and the typed path has the same tests it had.
