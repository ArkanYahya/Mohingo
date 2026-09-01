> **What this file is:** The visual language — color tokens, type scale, spacing, component states. Without this, every session invents its own shade of blue.
> **How to use it:** Treat values here as tokens, not suggestions — reference them by name (e.g. `color.primary`) in code rather than hardcoding hex/px values. Add a token here before using a new one in a component.

_Last verified: 2026-09-01 — initial design system established via brainstorming session._

# Design System

Direction: **playful/gamified** (Duolingo-style) — bright, energetic, rounded, celebratory on success. Must work equally well in Arabic (RTL) and English (LTR).

## Color

| Token | Light | Dark | Usage |
|---|---|---|---|
| `color.background` | `#FFFFFF` | `#121417` | App/screen background |
| `color.surface` | `#F5F7FA` | `#1E2126` | Cards, exercise panels |
| `color.text` | `#1A1D22` | `#F0F2F5` | Primary text |
| `color.text.muted` | `#6B7280` | `#9AA1AC` | Secondary/help text |
| `color.primary` | `#3FB950` | `#4ADE68` | Primary actions, progress, "correct" feedback (green, growth/success association) |
| `color.accent` | `#FFB020` | `#FFC24D` | Streaks, XP, celebratory highlights |
| `color.danger` | `#E5484D` | `#FF6B6E` | Errors, "incorrect" feedback |
| `color.info` | `#3B82F6` | `#60A5FA` | Hints, informational callouts |

## Typography

Font pairing must have matched Arabic + Latin cuts so both scripts feel like one type system rather than two bolted together.

| Token | Font / size / weight | Usage |
|---|---|---|
| `type.display` | Baloo 2 (Latin) / Baloo Bhaijaan 2 (Arabic), 28sp, Bold | Level/block celebratory headers |
| `type.heading` | Baloo 2 / Baloo Bhaijaan 2, 20sp, SemiBold | Screen/unit titles |
| `type.body` | Noto Sans / Noto Sans Arabic, 16sp, Regular | Lesson content, explanations |
| `type.caption` | Noto Sans / Noto Sans Arabic, 13sp, Regular | Muted/help text, timestamps |

Both font pairs are available on Google Fonts and designed as RTL/LTR companions (matched x-height and rhythm).

## Spacing scale

4 / 8 / 12 / 16 / 24 / 32 / 48px — consistent across both text directions (Flutter's directional padding/margins used throughout, never hardcoded left/right).

## Radii / elevation

- Radii: 8px (inputs, small buttons), 16px (cards), 24px (large celebratory modals — level-up, streak)
- Elevation: flat design with soft shadows on interactive surfaces only (cards, buttons); avoid heavy drop shadows to keep the playful/light feel

## Components

Per component, default / hover(press) / active(selected) / disabled / error states apply — hover states are less relevant on mobile but a pressed/ripple state is used instead:

- **Button (primary):** default = `color.primary` fill; pressed = darkened 10%; disabled = `color.text.muted` fill at 40% opacity; no error state (buttons don't show errors directly)
- **Exercise answer option:** default = `color.surface`; selected = `color.primary` border; correct = `color.primary` fill + check icon; incorrect = `color.danger` fill + X icon
- **Input (writing exercises):** default = `color.surface` with border; focused = `color.primary` border; error = `color.danger` border + inline message below
- **Progress bar (unit/block):** filled portion = `color.primary`; unfilled = `color.surface`
- **Card (unit/lesson tile):** default = `color.surface`, `radii.16`; locked (not yet unlocked) = 50% opacity + lock icon overlay

## Theming rules

- Light/dark switching mechanism: follows system theme (`ThemeMode.system` in Flutter), no manual in-app override for MVP.
- Hard rule: never hardcode a color or use non-directional (`left`/`right`) padding/alignment — always reference a `color.*` token and use Flutter's directional (`start`/`end`) layout properties, since the UI must mirror correctly between Arabic (RTL) and English (LTR).
