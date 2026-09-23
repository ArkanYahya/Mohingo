> **What this file is:** The definition of what the app is, who it's for, and what counts as "done." Prevents scope from being reinvented differently in each session.
> **How to use it:** Update when scope actually changes (a feature is added/cut/reprioritized). Keep it at the level of *what and why*, not *how* — implementation belongs in [ARCHITECTURE.md](ARCHITECTURE.md).

_Last verified: 2026-09-23 (`release/v1.0.0`) — 1.0.0 adds a first-run agreement, the app guide, About (version, privacy policy, terms, licences) and in-app account deletion; the colour-theme choice was removed ([ADR 0011](adr/0011-first-run-agreement-app-guide-and-account-deletion.md)). Previously verified 2026-09-23 (`claude/firebase-auth-sync-ji1cww`) — **optional accounts and cross-device progress** added to the post-MVP scope, and the onboarding flow no longer says there are no accounts ([ADR 0010](adr/0010-optional-accounts-and-progress-sync.md)). Previously verified 2026-09-22 (`feature/level-standard-and-content-versioning`) — A1 held to A2's standard, added to the post-MVP scope list with the counts. Previously on this branch: a unit now tells the learner when its content changed under them, added to the post-MVP scope list; and corrected a stale claim that one Settings string still named a level literally — `fc8fe56` fixed it, and no string value in either ARB names a level now. Earlier the same day (`feature/a2-pilot-u1`): flow 2 (placement) rewritten: the test now covers every released level, with the block pass and drill-down that keep it short, and a result can start a learner in A2. Earlier the same day: scope change: **A2 is no longer a preview, it is a second level a learner can study.** Its twelve units were authored to A1's standard and its two capstones written, so "in scope" now means A1 and A2 (B1-C2 remain roadmapped). Recorded below with the two honest caveats that come with it: A2's Arabic was written by AI and machine-checked for script, not read by a native speaker; and only the Learn tab follows the learner's level, so everything else in the app still shows A1. See [ROADMAP.md](ROADMAP.md) and [ADR 0006](adr/0006-multiple-levels.md). Previously verified 2026-09-20 (`feature/a2-current-level`) — corrected "CEFR levels beyond A1 are roadmapped, not built": A2's content now ships inside the app as a not-yet-released level — its units are browsable, its lessons aren't — while B1–C2 remain roadmapped only; see [ADR 0006](adr/0006-multiple-levels.md) and [ROADMAP.md](ROADMAP.md). Also noted that flow 5's "recommend, never block" principle now extends to levels, not just units. Previously verified 2026-09-09 — onboarding and progress-gating flows updated for the local-only, free-access v1 decided this session; see [ADR 0004](adr/0004-local-only-v1-no-firebase-backend.md). Phase 10 corrected stale "progress gating" wording in Success criteria (the actual v1 model is recommendation-only, per flow 5) and resolved 3 of the 4 Open questions below against what actually got built. Added flow 4's read-only lesson-answer-review step (Learn tab only) — see docs/superpowers/specs/2026-09-09-lesson-answer-review-design.md._

# Product

## Problem

Self-directed adult learners whose native language is Arabic need a structured way to learn English — one that follows the same logical, level-by-level progression as established resources (e.g. Oxford), rather than disconnected practice or drilling. Mohingo provides that structure, organized around the CEFR scale (A1 through C2).

## Target users

Self-directed adult learners, native Arabic speakers, learning English on their own (not in a classroom, not assigned by a teacher). The product is designed to eventually serve the full CEFR range (A1–C2); the MVP targets learners starting from zero (A1).

## Scope

### In scope (MVP)

- Full CEFR A1 level content (~70–100 guided-learning-hours worth), organized into the standard thematic blocks:
  1. Alphabet, pronunciation, numbers, greetings
  2. Personal information, classroom language, basic nouns
  3. Present simple verbs, basic questions, common adjectives
  4. Short reading texts, simple writing tasks, listening to slow speech
- All 4 CEFR skills: reading, listening, writing, speaking
- A placement test (confirms/assigns starting level; it covers every released level — A1 and A2 today — and never claims one above them)
- Bilingual Arabic/English UI (all app chrome — navigation, buttons, instructions)
- Bilingual explanations for grammar/vocabulary (contrastive notes — e.g. explaining how an English structure differs from the Arabic equivalent)
- RTL (Arabic) + LTR (English) layout support throughout
- AI-generated lesson content, curated and reviewed before publishing (content pipeline: generate → review → publish)
- A recommended unit-by-unit path with mastery tracking (not a hard lock — see key user flow 5)

### Also in scope, added after the MVP

- **Full CEFR A2 level content**, released 2026-09-21 (the bundle estimates 95–130 minutes per unit, so 19–26 hours of material; the CEFR reference band that [ROADMAP.md](ROADMAP.md) scopes against is far larger, as it is for A1): twelve thematic units (Life Now, Past Experiences, People & Relationships, Home & Neighbourhood, Food/Cooking/Services, Travel Plans, Health & Well-being, Work & Study, Technology & Communication, Stories & Entertainment, Nature & Everyday Problems, Invitations & Events), 84 lessons, 432 activities, its own Final Mission ("Host a Visitor") and Final Assessment, built to the same shape and the same four-skill balance as A1. A learner reaches it from the Learn tab's level switcher — once A1 is complete, or by choosing to open it early, since progression recommends and never blocks (flow 5).
  - **One thing this deliberately does not yet include.** A2's Arabic (units 3-12) was written by AI and checked by test only for presence and script; it was then read and confirmed by the project's Arabic-speaking owner on 2026-09-21, which is what closed it — a gate that proves a field contains Arabic and isn't the English copied across cannot prove it reads naturally. The second gap — every tab still showing A1 whatever level the learner was in — is now closed: step 2b landed tab by tab and the placement test last, so a learner studying A2 gets A2 everywhere. The last ARB string that named a level literally (`settingsProfileMeta`) was fixed by `fc8fe56`: no string value in `app_en.arb`/`app_ar.arb` names one now. Both are tracked in [ROADMAP.md](ROADMAP.md).

- **A unit tells the learner when its content changed under them.** Content improves after people have studied it. When an update takes away an activity a learner had answered, or moves a unit's required Can-Do objectives, that unit says so on the Learn tab — once, below whatever it already said, blocking nothing and asking for nothing. A unit whose content only grew says nothing. Their progress is always kept: nothing here deletes or rewrites recorded evidence.

- **A1 held to A2's standard** (2026-09-22). Running the level gate suite over A1 for the first time found roughly 290 content items the newer level would have been refused for: 56 speaking tasks with nothing to reply to, 60 lessons opening on 0-3 lines of conversation, 53 listed words and 32 listed phrases never used, 13 mediation tasks with nothing to relay, 13 ungradeable mastery speaking tasks, 44 English-only prompts, and four units requiring nothing of a skill they teach. All were fixed additively — no activity id moved, no mode changed — so nobody's recorded progress was invalidated; a learner who had mastered U2, U8, U11 or U12 re-evidences one new objective through activities they already did.

- **Optional accounts and cross-device progress** (2026-09-23, [ADR 0010](adr/0010-optional-accounts-and-progress-sync.md)). A learner can create an account (email and password, or Google) from Settings and keep their progress — lessons, answers, test results, review schedules, saved words and phrases, levels, name — across phones and reinstalls. It is never required: the app starts, teaches and records progress exactly as before without one, and a learner who signs in later is asked whether this phone's progress should join their account. Sign out and another person can sign in on the same phone without seeing it. "Reset progress" while signed in resets every phone on the account, after saying so. Android first; iOS needs Sign in with Apple before it can offer Google sign-in.

### Explicitly out of scope (for now)

- Monetization / payments (no paid tiers, subscriptions, or ads)
- Social / community features (no leaderboards, friends, sharing, forums)
- Teacher / classroom tools (no assigning content or tracking groups of students)
- Any taught language other than English
- Any native/interface language other than Arabic and English
- CEFR levels beyond A2 — B1–C2 remain roadmapped, not built, and the app never claims a placement result above the top released level (see [ROADMAP.md](ROADMAP.md))

## Success criteria

The MVP is "done" when all A1 content and mechanics are built and functional: all 4 thematic blocks, all 4 skills, the placement test, bilingual UI/explanations, and unit progress tracking (recommendation-based, never a hard lock — see flow 5) all work end-to-end. This is a feature-completeness bar, not a pedagogical-outcomes bar — it is not gated on real learners completing the level yet.

## Key user flows

1. **Onboarding** — the learner accepts a short first-run agreement (what stays on the phone and what can leave it), then a skippable guide over the real Home screen shows where everything is; they start straight away on a local profile (no sign-up step), with Arabic as native language, in bilingual UI. Creating an account is optional and lives in Settings → Account & sync ([ADR 0010](adr/0010-optional-accounts-and-progress-sync.md)).
2. **Placement test** — learner takes a short test that covers every released level, A1 and A2 today. It passes over each level's units in blocks of three or four, one question per unit, and only opens up a block it fails — so a complete beginner answers about 7 questions and a learner who already knows both levels about 25. The result is a unit to start at ("A2 Unit 5 is where to begin"), or that the top released level looks mastered; it never claims a level the app has no content for. Tapping "Start at …" moves the learner into that level, opening it if they hadn't reached it — the same thing the Learn tab's lock sheet offers as "Open A2 anyway".
3. **Level overview** — learner sees the level they're in broken into its units (A1's 13, A2's 12), and can switch between the levels that have content.
4. **Unit lesson flow** — within a unit: vocabulary (with bilingual glosses) → grammar instruction (bilingual explanation) → guided practice/drills → reading passage → listening exercise → writing task → speaking task → end-of-unit assessment. Reopening a lesson that's already reached its final activity (Learn tab only) shows a read-only review of the learner's latest answer to each activity first — correct/incorrect, and the correct answer where one exists — rather than dropping back into a blank replay; an explicit "Practice again" button is the only way from there into a full live replay, which still appends fresh evidence rather than overwriting history (see [DATA_MODEL.md](DATA_MODEL.md)). The Tests tab's own retake flows (Final Mission, Final Assessment, the Placement Test) are unaffected — a separate, later decision.
5. **Progress tracking, not hard gating** — the app recommends the next unit via mastery evidence (per-CanDo-objective, tracked separately per skill — see [DATA_MODEL.md](DATA_MODEL.md)), but a learner may freely open any unit, vocabulary, grammar, review, or test screen at any time; a block completes when all its units are mastered. The same recommend-don't-block principle now extends to levels: a level the learner hasn't reached, or one the app hasn't released, explains why and offers a way forward (take the placement test, open it anyway, or just look at what it covers) rather than a dead end — see [UX_PRINCIPLES.md](UX_PRINCIPLES.md) and [ADR 0006](adr/0006-multiple-levels.md).
6. **Level completion** — a level is complete when every unit that counts towards it is mastered (`levelComplete`; a starter unit like `A1-U0` doesn't count). Completing A1 is what opens A2 without the learner having to unlock it. Note that passing a level's Final Assessment does **not** currently count as completing it, although the level-design spec proposed it should — see [ROADMAP.md](ROADMAP.md).
7. **Progress tracking** — learner can see their position within a level (units completed, skills practiced) at any time. Progress is held per level, so a learner can hold progress in A1 and A2 at once.

## Open questions

- ~~How is speaking practice actually assessed?~~ **Resolved**: on-device speech-to-text checks task completion only (never pronunciation/fluency scoring), with a typed-answer fallback that's always available and never recorded as speaking evidence — see [ADR 0003](adr/0003-on-device-speech-writing-assessment-for-mvp.md) and [TECH_STACK.md](TECH_STACK.md).
- ~~How is writing practice graded?~~ **Resolved**: rules-based exact/near-match checking against the bundle's own `accepted` answer list where one is declared; free-response items with no `accepted` list are recorded but reported honestly as not-yet-scored (`notAutoGraded`/"pending review") rather than guessed at — no AI-graded free text in v1, see [TECH_STACK.md](TECH_STACK.md)'s "Explicitly rejected" table.
- ~~What does the content review workflow look like in practice?~~ **Resolved**: the separate dev-time curriculum tool's own pipeline (LLM draft → author review/edit → `validate-a1.mjs`/`audit-quality.mjs`/`build-a1.mjs`) produces one versioned `dist/a1-course-bundle.json`, copied into the app as a static asset — no in-app review queue or approval states exist, since content authoring never happens on-device. See [ARCHITECTURE.md](ARCHITECTURE.md)'s content-loading flow.
- Post-MVP: will additional native languages (beyond Arabic) ever be supported, or is the bilingual Arabic/English design permanent? Affects how hard-coded vs. localizable the UI layer should be. Still open — no decision made this session.
