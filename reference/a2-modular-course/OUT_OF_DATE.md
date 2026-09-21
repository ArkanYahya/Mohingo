# This package is behind the app — and much further behind than A1's

The app loads `assets/content/en/A2/a2-course-bundle.json`. This package produced the **first** version of that file (imported 2026-09-20), and nothing since. A2 was then written, unit by unit, in the shipped asset itself, because what this package generates parses but does not teach:

- every "conversation" was a single line by a single speaker (72 of 72), and 38 of them had no Arabic at all;
- the **present perfect appeared nowhere** in its 72 grammar records — in the level CEFR most defines by it;
- listening was 80 activities against 232 reading;
- all 120 productive tasks carried a retired rubric-name array as their `evaluation`, which the app's parser drops to `null` — so no speaking, writing or mediation answer could ever have been graded;
- no mediation task supplied the material it asked the learner to relay (0 of 24), no `speak` activity had partner turns (0 of 96), and no unit had its L6 model text;
- 291 distinct prompts across 432 activities, because one template built every lesson.

The shipped file now has real conversations, working graders, source cards, partner turns, model texts, the present perfect at U8 and U12, and 432 distinct prompts. Its capstones were written from scratch and their pass marks lowered from this package's 0.75 to 0.6, matching A1.

**Do not regenerate from `tools/` and copy the output into the app.** That would replace the level with the skeleton above. `test/content/a2_*` in the app repo would reject it immediately — that suite exists for exactly this — but the loss would still be a day's work to unpick.

To author here again, first port the shipped bundle's content back into these sources.

See `docs/ARCHITECTURE.md` ("Content" under Key flows) and `docs/superpowers/specs/2026-09-19-a2-level-design.md` ("What actually shipped") in the app repo.
