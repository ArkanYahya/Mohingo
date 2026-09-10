> **What this file is:** The visual language — color tokens, type scale, spacing, component states. Without this, every session invents its own shade of blue.
> **How to use it:** Treat values here as tokens, not suggestions — reference them by name (e.g. `color.primary`) in code rather than hardcoding hex/px values. Add a token here before using a new one in a component.

_Last verified: 2026-09-10 — Stage 3 of the "full energy" redesign: the unit overview screen (one unit's lesson list) was rebuilt as a vertical path of 52px circular icon nodes with a connector line between them, mirroring Learn's unit spine at lesson granularity — see the new "Lesson node (unit overview)" Components entry below. `StatusIndicator` gained an optional `colorOverride` param so the one "current" (next-to-do) lesson can be forced to the brand accent regardless of its raw state. Earlier the same day, Stage 2: Home's "Continue learning" card moved from `colorScheme.primaryContainer` to a full-bleed `colorScheme.primary` fill with a 24px radius (Home's one deliberately vivid "hero" element), and a new "Tasks today" row (3 tiles — Finish a lesson / Review 5 words / Speak once) was added, each filled `colorScheme.primary` until its daily target is reached, then `feedbackTheme.success` — see Components below. Previously verified 2026-09-09 — added a semantic `FeedbackTheme` (`ThemeExtension`: `success`/`onSuccess`/`successContainer`/`onSuccessContainer`) and moved every "correct answer" visual (the `ChoiceActivityView` option fill/border, `ActivityFeedbackBanner`'s correct case, `StatusIndicator.mastered`) off `colorScheme.primary`/`primaryContainer` onto it — see the Color and Components sections below. Reason: once `primary` became a per-theme brand accent (this same day's earlier change, described next), "correct" stopped reading as universally green — e.g. `warmTerracotta`'s orange `primary` made a correct answer look orange, not affirming. `FeedbackTheme` is a fixed, theme-seed-independent green in both light and dark mode, deliberately not derived from `ColorScheme.fromSeed`. Light-mode `colorScheme.primary`/`primaryContainer` are now overridden per seed with hand-picked flat brand accents (`AppColorSeed.brandPrimary`/`onBrandPrimary`/`brandPrimaryContainer`/`onBrandPrimaryContainer`), fixing a "the app reads muted next to WhatsApp/Telegram" report and a same-day follow-up ("some are vivid and some are mute" — `primaryContainer` and the Settings colour-theme picker's swatches were still showing the old muted tones); every other role (surfaces, secondary, `tertiary` — a known remaining gap, see below — error, dark mode) is untouched — see the Color section below. Previously verified 2026-09-04: added StatusIndicator component; corrected streakAccent naming; added the `onStreakAccent` foreground token (fixes a 3.64:1 AA contrast failure on the light-theme streak card) and `StatusIndicator.semanticLabelOverride` (lesson/vocabulary rows no longer announce "Mastered") — see the 2026-09-04 UI redesign plan and its final fix pass. Replaced the bright Duolingo-style direction with a calm, adult Material 3 system per this session's Decision Gate ("calm visuals, light gamification"); see [ADR 0004](adr/0004-local-only-v1-no-firebase-backend.md). Tokens now map onto Flutter's `ColorScheme` roles instead of ad hoc names, since [TECH_STACK.md](TECH_STACK.md) commits to Material 3 + `ColorScheme` + `ThemeExtension`. Phase 10 confirmed the theme-mode and colour-theme pickers described below are now real, working Settings UI (previously the preference providers existed but nothing exposed them)._

# Design System

Direction: **calm, adult-oriented Material 3**, evolved toward more visual energy from 2026-09-09 onward (see the vivid-accent and "full energy" entries in Last verified above) — restrained surfaces and generous spacing stay, but key accents (the brand `primary` colour, Home's hero card, daily-task tiles) are now deliberately vivid and saturated rather than muted, based on real-device feedback that the earlier, flatter palette read as bland next to mainstream apps. Still: one modest gamification element (a streak/progress indicator, not XP/badges/leaderboards), never a stats-heavy or celebratory-on-every-success feel. Must work equally well in Arabic (RTL) and English (LTR).

## Color

Generated via `ColorScheme.fromSeed(seedColor: ..., brightness: ...)` — Material 3's tonal-palette algorithm derives the full light/dark role set (`primary`, `onPrimary`, `primaryContainer`, `secondary`, `tertiary`, `surface`, `surfaceVariant`, `error`, etc.) from one seed colour per theme, which is what makes "selectable colour themes" (Settings, per the app's requirements) a matter of swapping a seed value rather than hand-maintaining N full palettes.

**Default seed — `color.seed.calm-teal`: `#2A6F77`.** Chosen to read as calm/trustworthy rather than energetic (unlike the old bright `#3FB950` green), while keeping a plausible growth/learning association. Representative derived roles (exact values are the algorithm's output, not hand-picked — regenerate via Flutter's Material theme builder or `ColorScheme.fromSeed` at implementation time):

| Role | Light (approx.) | Dark (approx.) | Usage |
|---|---|---|---|
| `colorScheme.surface` | near-white, warm neutral | near-black, warm neutral | App/screen background |
| `colorScheme.surfaceContainer` | light neutral | dark neutral | Cards, exercise panels |
| `colorScheme.onSurface` | near-black | near-white | Primary text |
| `colorScheme.onSurfaceVariant` | mid grey | light grey | Secondary/help text |
| `colorScheme.primary` | **hand-picked flat brand accent** — see below | lighter teal tone (pure algorithm output) | Primary actions, selected/focused state |
| `colorScheme.error` | muted red | lighter muted red | Errors, "incorrect" feedback |
| `colorScheme.tertiary` | muted warm tone | lighter warm tone | Hints, informational callouts |

**Light-mode `primary`/`primaryContainer` are overridden, every other role is not (`AppColorSeed.brandPrimary`/`onBrandPrimary`/`brandPrimaryContainer`/`onBrandPrimaryContainer`, applied in `AppTheme._build`).** `ColorScheme.fromSeed`'s own light-mode `primary` sits at a deliberately dark tone (to guarantee white-text contrast), which read closer to ink than to an accent and prompted a "the app feels muted next to WhatsApp/Telegram" report. Since `primary` is the one role behind buttons, selected answers, progress fills and the "correct" state (see Components below), swapping just that role for a flat, saturated tone in the same hue family fixes the complaint without touching the calm surfaces/secondary/tertiary/error roles the original ADR 0004 direction still holds for.

The first pass overrode only `primary`/`onPrimary` and left `primaryContainer` as the algorithm's own pale, near-pastel tint — which produced a follow-up report ("some are vivid and some are mute"): the "Correct!" feedback banner (since moved to `feedbackTheme.successContainer` — see Semantic feedback tokens above) and Home's "Continue learning" card both used `primaryContainer`, sitting right next to the now-vivid `primary` buttons/chips, so the pale container read as a mismatched, muted surface rather than a lighter tint of the same accent. `primaryContainer`/`onPrimaryContainer` are now overridden too, with a punchier (still clearly lighter than `primary`, just not desaturated all the way to pastel) tint in the same hue family. The Settings colour-theme picker previews `brandPrimary` (not the raw `seedColor`) for the same reason — an earlier version showed the muted seed while the rest of the app showed the vivid accent, two visibly different colours for the same "theme."

Each value (`brandPrimary` and `brandPrimaryContainer`) was swept across lightness at full saturation and checked against the 4.5:1 WCAG 2.1 AA floor with its paired on-colour — white passes for `slate-indigo`/`warm-terracotta` but not for `calm-teal` (a vivid cyan), mirroring `GamificationTheme.onStreakAccent`'s own white-fails-AA case below. Dark mode is left as pure algorithm output: its `primary`/`primaryContainer` are already light, visible tones against the dark surface, so they don't have the same problem.

`colorScheme.tertiary` (used by `StatusIndicator`'s `inProgress`/`needsReview` states — the half-filled/refresh icons on every lesson, unit, and vocabulary row) is a known remaining gap: it's still the algorithm's muted tone, so it can still look flat next to a `mastered` row's now-vivid `primary` checkmark on the same list. Left alone deliberately for now, pending a decision on what an accessible "in progress" accent should be (not simply `primary` again — the two states need to stay visually distinct).

| Seed | `brandPrimary` (light `primary`) | `onBrandPrimary` | `brandPrimaryContainer` (light `primaryContainer`) | `onBrandPrimaryContainer` |
|---|---|---|---|---|
| `color.seed.calm-teal` | `#00CBE5` | `#00363C` | `#3DE8FF` | `#00363C` |
| `color.seed.slate-indigo` | `#3645E2` | `#FFFFFF` | `#9DA4F1` | `#1F2C61` |
| `color.seed.warm-terracotta` | `#C74605` | `#FFFFFF` | `#FBA174` | `#542105` |

**Approved alternate seeds (Settings colour-theme picker):** `color.seed.slate-indigo` (`#3F4A7A`), `color.seed.warm-terracotta` (`#8A5238`) — same generation mechanism, swap the seed. No theme may be added ad hoc outside this approved list without updating this doc.

**Semantic feedback tokens (`FeedbackTheme`, a `ThemeExtension`, not `ColorScheme` roles):** `success`/`onSuccess`/`successContainer`/`onSuccessContainer` — a fixed, real green used for every "this answer is correct" visual, deliberately independent of the active colour-theme seed. Once `primary` (above) became a per-theme brand accent rather than a fixed hue, a correct answer under `warmTerracotta` would otherwise fill orange, which doesn't read as affirming the way green universally does. Used by: `ChoiceActivityView`'s correct option (fill = `success`, text/icon = `onSuccess`; border variant on media options), `ActivityFeedbackBanner`'s correct case (`successContainer`/`onSuccessContainer`, mirroring how `primaryContainer` is used for its other states), and `StatusIndicator.mastered` (`success`). The `neutral`/"selected but not yet graded" states in these same components are unaffected and still use `colorScheme.primary` — that represents the learner's pick, not a verdict. Values: `success` `#157A36` light / `#4ADE80` dark, `onSuccess` `#FFFFFF` light / `#0B2E17` dark, `successContainer` `#E3F5E8` light / `#16311F` dark, `onSuccessContainer` `#0F5C28` light / `#7EE39C` dark — each pair checked against the 4.5:1 WCAG 2.1 AA floor.

**Gamification tokens (`ThemeExtension`, not `ColorScheme` roles):** `streakAccent` — a single warm amber (`#B7791F` light / `#D9A441` dark), used *only* for the one streak/progress element on Home per the "light gamification" decision. Deliberately not reused elsewhere, so it doesn't creep into a general accent colour the way the old `color.accent` did. Its paired foreground is `onStreakAccent` (`#1A1200` light / `#2B1D00` dark) — **always use it for content drawn on `streakAccent`, never `colorScheme.onPrimary`**: `onPrimary` is white in the light theme and computes to only 3.64:1 on `#B7791F`, below the 4.5:1 AA floor in [UX_PRINCIPLES.md](UX_PRINCIPLES.md). The shipped pairs measure 5.10:1 (light) and 7.30:1 (dark).

Exercise feedback (correct/incorrect) is never colour-alone — always paired with an icon + text, per [UX_PRINCIPLES.md](UX_PRINCIPLES.md).

## Typography

Font pairing must have matched Arabic + Latin cuts so both scripts feel like one type system rather than two bolted together. Moved off the rounded, playful Baloo pairing to a calmer, more adult-reading pairing for headings; body copy is unchanged (it was already calm).

| Token | Font / size / weight | Usage |
|---|---|---|
| `type.display` | Inter (Latin) / IBM Plex Sans Arabic, 28sp, SemiBold | Level/unit headers |
| `type.heading` | Inter / IBM Plex Sans Arabic, 20sp, Medium | Screen/unit titles |
| `type.body` | Noto Sans / Noto Sans Arabic, 16sp, Regular | Lesson content, explanations |
| `type.caption` | Noto Sans / Noto Sans Arabic, 13sp, Regular | Muted/help text, timestamps |

All fonts are on Google Fonts; Inter/IBM Plex Sans Arabic and Noto Sans/Noto Sans Arabic are both designed with matched x-height/rhythm as RTL/LTR companions. Must support Dynamic Type/text scaling without clipped controls, per [UX_PRINCIPLES.md](UX_PRINCIPLES.md).

## Spacing scale

4 / 8 / 12 / 16 / 24 / 32 / 48px — consistent across both text directions (Flutter's directional padding/margins used throughout, never hardcoded left/right).

## Radii / elevation

- Radii: 8px (inputs, small buttons), 12px (cards), 20px (large modals — reduced from the old 24px "celebratory" scale to read calmer, still Material-3-legible as a modal).
- Elevation: Material 3 tonal elevation (surface-tint-based, not heavy drop shadows) — reinforces the restrained, adult feel more directly than the old "flat + soft shadow" description.

## Components

Per component, default / hover(press) / active(selected) / disabled / error states apply — hover states are less relevant on mobile but a pressed/ripple state is used instead:

- **Button (primary):** default = `colorScheme.primary` fill; pressed = Material 3 state-layer overlay; disabled = `colorScheme.onSurface` at 38% opacity (M3 standard disabled treatment); no error state (buttons don't show errors directly)
- **Exercise answer option:** default = `colorScheme.surfaceContainer`; selected = `colorScheme.primary` border; correct = `feedbackTheme.success` fill + check icon; incorrect = `colorScheme.error` fill + X icon
- **Input (writing exercises):** default = `colorScheme.surfaceContainer` with border; focused = `colorScheme.primary` border; error = `colorScheme.error` border + inline message below
- **Progress bar (unit path):** filled portion = `colorScheme.primary`; unfilled = `colorScheme.surfaceContainer`
- **Card (unit/lesson tile):** default = `colorScheme.surfaceContainer`, `radii.12`; states are "not started / in progress / needs review / mastered" (per [PRODUCT.md](PRODUCT.md)'s free-access model), never a "locked" visual — there is no route-level lock in v1, see [ARCHITECTURE.md](ARCHITECTURE.md)
- **Status indicator:** icon + color, shape-distinguishable across all 4 states (never color alone), plus a screen-reader semantic label — not paired with inline visible text, used compactly on unit spine nodes and lesson/vocabulary/test rows. 4 states:
  - `notStarted`: outline circle icon, `colorScheme.onSurfaceVariant` color, "Not started" semantic label
  - `inProgress`: half-filled ring icon, `colorScheme.tertiary` color, "In progress" semantic label
  - `needsReview`: refresh icon, `colorScheme.tertiary` color, "Needs review" semantic label
  - `mastered`: filled check circle icon, `feedbackTheme.success` color (a fixed green, independent of the active colour theme — see Semantic feedback tokens above), "Mastered" semantic label
  - `semanticLabelOverride` replaces the state-derived label (icon/colour unchanged) where "Mastered" would be wrong: lesson rows say "Completed"/"مكتمل" and vocabulary rows say "Learned"/"محفوظة", because only a *unit* reaching `MasteryAggregationService`'s policy is mastery as [GLOSSARY.md](GLOSSARY.md) defines it
  - `colorOverride` replaces the state-derived colour (icon shape/label unchanged) — used by the unit overview's "current lesson" node (below) to force the brand accent regardless of whether the raw state is `notStarted` or `inProgress`
- **Streak/progress indicator (Home only):** the one approved gamification element — `streakAccent` fill, small, non-modal, no animation beyond a subtle count-up; must respect reduced-motion settings per [UX_PRINCIPLES.md](UX_PRINCIPLES.md)
- **Continue-learning hero card (Home only):** `colorScheme.primary` fill (not `primaryContainer` — see Color above), `onPrimary` text, 24px radius (Home's one deliberately larger-than-`radii.12` element, reserved for this single "hero" card so it doesn't dilute into an inconsistent app-wide radius change), CTA button inverted (`onPrimary` background, `primary` foreground) for contrast against the vivid fill
- **Daily-task tile (Home's "Tasks today" row, 3 tiles):** `colorScheme.primary` fill + `onPrimary` text/icon while the day's target isn't yet reached; once `done >= target`, the tile switches to `feedbackTheme.success`/`onSuccess` and its icon becomes a checkmark — the same semantic-green "this is done/correct" language as an exercise answer (see Semantic feedback tokens above), so a completed task reads as unambiguously done rather than just "still the brand colour." 18px radius. Progress shown as a plain `done/target` digit pair (e.g. `0/5`) — no translation needed, since digits and `/` carry no natural-language content; only the task label itself (`homeTaskFinishLesson` etc.) is bilingual.
- **Lesson node (unit overview screen):** a 52px circular icon node per lesson, connected by a 2px vertical rail (mirrors Learn's unit spine, scaled to lesson granularity — see `unit_path_view.dart`'s `_SpineTile`), wrapping a `StatusIndicator` (24px) rather than reimplementing icon logic. Row states:
  - default (not started, not the current lesson): white/`colorScheme.surface` circle, `colorScheme.outlineVariant` border, `StatusIndicator`'s own default colour; no row tint
  - **current** (the single next lesson to do — `currentLessonId`, first non-finished lesson in curriculum order; may be `notStarted` or `inProgress`): `colorScheme.primary` circle border (2.5px) and icon (via `StatusIndicator.colorOverride`), row tinted `colorScheme.primaryContainer` with a `colorScheme.primary` border — this is what makes "do this one next" legible even when the lesson has never been opened, distinct from an ordinary not-started lesson further down the list
  - **mastered**: solid `feedbackTheme.success` circle, `feedbackTheme.onSuccess` icon, row tinted `feedbackTheme.successContainer` — same semantic-green language as everywhere else "correct/done" is shown
  - **mission** (`lesson.lessonType == 'mission'`): overrides every other state — a full-bleed `colorScheme.primary` card (not a tinted row), a translucent-white circle with a flag icon, `onPrimary` text; mirrors the unit spine's own milestone treatment for mission-bearing units
  - header progress bar + "`unitOverviewLessonsComplete`" caption ("N of M lessons complete") above the list, same `LinearProgressIndicator`/`colorScheme.primary` fill pattern as Home's level-progress card

## Theming rules

- Light/dark switching mechanism: light / dark / system, user-selectable in Settings (not system-only as originally scoped) — changes apply immediately, no restart, per the app's Settings requirements.
- Colour-theme switching: user-selectable from the approved seed list above, applied via `ColorScheme.fromSeed`; also applies immediately.
- Hard rule: never hardcode a color or use non-directional (`left`/`right`) padding/alignment — always reference a `colorScheme.*`/theme-extension token and use Flutter's directional (`start`/`end`) layout properties, since the UI must mirror correctly between Arabic (RTL) and English (LTR).
