# UI Navigation & Progress-Feedback Redesign — Home, Learn, Review, Tests

**Status:** Approved design, ready for implementation planning
**Date:** 2026-09-04

## Context

Real on-device testing surfaced that the app's navigation and progress feedback aren't legible, even though the underlying data (progress state, attempt history) already exists. A full code audit of the four affected screens found, concretely:

- **Home** (`lib/features/home/presentation/home_screen.dart`) renders exactly one widget — a "Continue: [unit]" card — and nothing else. A `GamificationTheme.streakAccent` color token already exists in the theme (`lib/core/theme/gamification_theme_extension.dart`) but is never used anywhere in the app.
- **Learn**'s only progress signal is a small colored pill per unit (`unit_path_view.dart`) showing `mastered`/`inProgress`/not-started. There is no aggregate progress at the level screen, no per-lesson state at all in the unit's lesson list (`unit_overview_screen.dart`), in-lesson progress is a plain text fraction in the `AppBar` title only ("3 / 7"), and lesson completion (`_LessonCompleteScreen` in `lesson_player_screen.dart`) is a static generic screen — no score/tally, no next-step link, identical whether the learner aced the lesson or barely passed.
- **Review**'s confidence buttons (`ReviewConfidenceRow`, Again/Good/Easy) produce zero visible feedback on tap — no highlight, no confirmation, no forward motion. Vocabulary/chunk list rows show a favorite star but no due/new/mastered state.
- **Tests**' 5 cards (`TestsHomeScreen`) look identical regardless of whether they've ever been taken — no "last attempt" state. The final assessment's result screen shows pass/not-met text labels with no score and no next-step link, in contrast to the placement test's result screen, which already does this well (icon + per-skill tally + a "go here next" button).
- Separately (noted but out of scope here): DESIGN_SYSTEM.md's specified typography system (Inter/IBM Plex Sans Arabic + Noto Sans pairing) isn't wired into `app_theme.dart` — the app is still on Flutter's default text theme.

Full file-by-file findings are in the session's audit (see git blame / conversation history around 2026-09-04 if needed) — this doc captures the resulting decisions, not the raw audit.

## Goals

- Every one of the four screens must make "where am I" and "what have I completed" visually legible without relying on small `AppBar` text.
- Stay inside the design direction already committed in DESIGN_SYSTEM.md: calm, adult Material 3, restrained, generous spacing, **exactly one** modest gamification accent (a streak/progress indicator) — explicitly not XP, badges, leaderboards, or a mascot.
- Reuse existing tokens and patterns (color roles, spacing scale, radii, the existing list-based visual language, the `ActivityFeedbackBanner` feedback pattern) rather than inventing a new visual system.

## Non-goals

- No new gamification mechanics beyond the streak indicator — XP, leaderboards, and achievements are explicitly rejected, per the existing DESIGN_SYSTEM.md decision.
- Not fixing the raw-error-text violations of UX_PRINCIPLES.md found during the audit (several screens display `'$error'` directly) — a real bug, but orthogonal to navigation/progress legibility; track separately.
- Not implementing DESIGN_SYSTEM.md's typography spec (Inter/IBM Plex/Noto) — a pre-existing, separate gap.
- Not touching the Settings screen.

## Shared component: 4-state status indicator

A single reusable status-indicator widget covering the 4 states DESIGN_SYSTEM.md already specifies (`notStarted` / `inProgress` / `needsReview` / `mastered`) but which today are only partially implemented, and only on Learn's unit rows (3 of the 4 states). Visual mapping:

| State | Treatment |
|---|---|
| `notStarted` | Outline circle, `onSurfaceVariant` |
| `inProgress` | Half-filled ring, `tertiary` |
| `needsReview` | Refresh/rotate icon — color TBD at implementation (see Open Questions) |
| `mastered` | Filled circle + check, `primary` |

Every state pairs an icon with a color (never color alone), consistent with UX_PRINCIPLES.md's accessibility rule already followed by `ActivityFeedbackBanner`. Used on: Learn's unit spine nodes, Learn's lesson rows (new), Review's vocabulary/chunk rows (new), Tests' cards (new, as a completion state).

## Design: Home screen — full dashboard

Four stacked sections, in order:

1. **Streak card** — uses the previously-unused `GamificationTheme.streakAccent` token; streak count + short encouragement line.
2. **Continue card** — existing card, unchanged in substance (current unit title EN/AR + Continue button).
3. **A1 level-progress card** — an aggregate progress bar (filled = `primary`, unfilled = `surfaceContainer` — the "progress bar" component DESIGN_SYSTEM.md already specifies but which doesn't exist in code yet) + "X of 13 units mastered" caption.
4. **Review-due card** — count of items due, taps through to Review.

All bilingual (EN/AR) and RTL-safe per the project's standing rules — directional layout properties only, never hardcoded left/right.

## Design: Learn flow — journey spine with milestones

- **Level screen** (`level_catalog_screen.dart`): each `_LevelCard` gains a per-level aggregate indicator ("6/13 units" + a thin bar), in addition to the existing availability chip.
- **Unit list / level-detail screen** (currently `unit_path_view.dart`): replace the plain vertical list with a spine — a persistent thin vertical line, larger "milestone" markers with a title label at each Block boundary, regular nodes (using the shared status indicator) for each unit in between, and an explicit "you are here" marker at the learner's current position (not just implied by node color, as today).
- **Unit overview / lesson list** (`unit_overview_screen.dart`): add the shared status indicator to every lesson row. This is the single most concrete gap the audit found — today there is no per-lesson state at all, so a learner can't tell which lessons in a unit they've already done.
- **In-lesson progress** (`lesson_player_screen.dart`): add a visible progress bar/dot-strip in the body, replacing reliance on the `AppBar` title's "3 / 7" text as the only progress cue.
- **Lesson completion** (`_LessonCompleteScreen`): replace the static generic screen with a result view modeled on the placement test's `_ResultView` — a correct/incorrect tally (or per-skill breakdown, matching the activities actually attempted) and a concrete "what's next" CTA (next lesson if more remain, otherwise back to the unit's spine, now showing the updated state).

## Design: Review screen

- `ReviewConfidenceRow`: on tap — (a) briefly highlight the selected button, (b) show an inline confirmation reusing the existing `ActivityFeedbackBanner` visual pattern (e.g. "Saved — next review in N days"), (c) auto-advance to the next due word/chunk when reviewing from a queue context, instead of leaving the learner on an unchanged screen.
- `VocabularyListScreen` rows: add the shared status indicator (mapped to due/new/mastered) as a leading badge, alongside the existing favorite star.
- Bottom-nav Review tab: add a small due-count badge on the `NavigationDestination`, so the count is visible before opening the tab.

## Design: Tests screen

- `TestsHomeScreen` cards: each gains a state line under its subtitle — "Not yet taken" / "Completed — [summary]" / "In progress" — sourced from existing attempt-history data (no new persistence needed).
- `FinalAssessmentScreen`'s `_AssessmentResultView`: generalize the placement test's richer result pattern — add per-section score/percentage (not just pass/not-met text) and a "what's next" forward link/button (e.g. to a recommended remediation unit), matching what the placement test's result view already does.

## Testing

- Widget tests: the shared status-indicator component (all 4 states render a distinct icon+color+semantic label); `ReviewConfidenceRow`'s post-tap feedback and auto-advance; the lesson-complete screen's tally rendering under both pass and fail scenarios; Tests cards' state-line rendering across not-taken/completed scenarios.
- No new `integration_test/` coverage is required specifically by this redesign — that gap is tracked separately (see README.md's "Known limitations").

## Open questions

- **`needsReview` color/icon:** no dedicated token exists yet. Default to `tertiary` at higher emphasis unless a dedicated DESIGN_SYSTEM.md token is added during implementation.
- **Home's "Continue" destination:** whether it should jump straight into the lesson player (current behavior) or land on the unit's journey-spine view first. Default to current behavior (straight to lesson player) — least friction, and consistent with UX_PRINCIPLES.md's bias toward getting the learner into practice quickly.
