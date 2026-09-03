> **What this file is:** The visual language — color tokens, type scale, spacing, component states. Without this, every session invents its own shade of blue.
> **How to use it:** Treat values here as tokens, not suggestions — reference them by name (e.g. `color.primary`) in code rather than hardcoding hex/px values. Add a token here before using a new one in a component.

_Last verified: 2026-09-02 — replaced the bright Duolingo-style direction with a calm, adult Material 3 system per this session's Decision Gate ("calm visuals, light gamification"); see [ADR 0004](adr/0004-local-only-v1-no-firebase-backend.md). Tokens now map onto Flutter's `ColorScheme` roles instead of ad hoc names, since [TECH_STACK.md](TECH_STACK.md) commits to Material 3 + `ColorScheme` + `ThemeExtension`. Phase 10 confirmed the theme-mode and colour-theme pickers described below are now real, working Settings UI (previously the preference providers existed but nothing exposed them)._

# Design System

Direction: **calm, adult-oriented Material 3** — restrained, professional, generous spacing; one modest gamification element (a streak/progress indicator, not XP/badges/leaderboards) rather than a stats-heavy or celebratory-on-every-success feel. Must work equally well in Arabic (RTL) and English (LTR).

## Color

Generated via `ColorScheme.fromSeed(seedColor: ..., brightness: ...)` — Material 3's tonal-palette algorithm derives the full light/dark role set (`primary`, `onPrimary`, `primaryContainer`, `secondary`, `tertiary`, `surface`, `surfaceVariant`, `error`, etc.) from one seed colour per theme, which is what makes "selectable colour themes" (Settings, per the app's requirements) a matter of swapping a seed value rather than hand-maintaining N full palettes.

**Default seed — `color.seed.calm-teal`: `#2A6F77`.** Chosen to read as calm/trustworthy rather than energetic (unlike the old bright `#3FB950` green), while keeping a plausible growth/learning association. Representative derived roles (exact values are the algorithm's output, not hand-picked — regenerate via Flutter's Material theme builder or `ColorScheme.fromSeed` at implementation time):

| Role | Light (approx.) | Dark (approx.) | Usage |
|---|---|---|---|
| `colorScheme.surface` | near-white, warm neutral | near-black, warm neutral | App/screen background |
| `colorScheme.surfaceContainer` | light neutral | dark neutral | Cards, exercise panels |
| `colorScheme.onSurface` | near-black | near-white | Primary text |
| `colorScheme.onSurfaceVariant` | mid grey | light grey | Secondary/help text |
| `colorScheme.primary` | `#2A6F77`-derived tone | lighter teal tone | Primary actions, "correct" feedback |
| `colorScheme.error` | muted red | lighter muted red | Errors, "incorrect" feedback |
| `colorScheme.tertiary` | muted warm tone | lighter warm tone | Hints, informational callouts |

**Approved alternate seeds (Settings colour-theme picker):** `color.seed.slate-indigo` (`#3F4A7A`), `color.seed.warm-terracotta` (`#8A5238`) — same generation mechanism, swap the seed. No theme may be added ad hoc outside this approved list without updating this doc.

**Gamification token (`ThemeExtension`, not a `ColorScheme` role):** `gamificationAccent` — a single warm amber (`#B7791F` light / `#D9A441` dark), used *only* for the one streak/progress element on Home per the "light gamification" decision. Deliberately not reused elsewhere, so it doesn't creep into a general accent colour the way the old `color.accent` did.

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
- **Exercise answer option:** default = `colorScheme.surfaceContainer`; selected = `colorScheme.primary` border; correct = `colorScheme.primary` fill + check icon; incorrect = `colorScheme.error` fill + X icon
- **Input (writing exercises):** default = `colorScheme.surfaceContainer` with border; focused = `colorScheme.primary` border; error = `colorScheme.error` border + inline message below
- **Progress bar (unit path):** filled portion = `colorScheme.primary`; unfilled = `colorScheme.surfaceContainer`
- **Card (unit/lesson tile):** default = `colorScheme.surfaceContainer`, `radii.12`; states are "not started / in progress / needs review / mastered" (per [PRODUCT.md](PRODUCT.md)'s free-access model), never a "locked" visual — there is no route-level lock in v1, see [ARCHITECTURE.md](ARCHITECTURE.md)
- **Streak/progress indicator (Home only):** the one approved gamification element — `gamificationAccent` fill, small, non-modal, no animation beyond a subtle count-up; must respect reduced-motion settings per [UX_PRINCIPLES.md](UX_PRINCIPLES.md)

## Theming rules

- Light/dark switching mechanism: light / dark / system, user-selectable in Settings (not system-only as originally scoped) — changes apply immediately, no restart, per the app's Settings requirements.
- Colour-theme switching: user-selectable from the approved seed list above, applied via `ColorScheme.fromSeed`; also applies immediately.
- Hard rule: never hardcode a color or use non-directional (`left`/`right`) padding/alignment — always reference a `colorScheme.*`/theme-extension token and use Flutter's directional (`start`/`end`) layout properties, since the UI must mirror correctly between Arabic (RTL) and English (LTR).
