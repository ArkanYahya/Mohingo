# tool/meaning — the meaning signal's dev-time tools

Python, dev-time only; nothing here ships. The app side is
`OnnxMeaningSignalService` and `WordPieceTokenizer` under
`lib/features/activity_engine/` ([ADR 0011](../../docs/adr/0011-on-device-ai-for-free-answers.md)).

```
python -m pip install onnx onnxruntime

python tool/meaning/check_model_answers.py                      # every keyword-graded mastery speak/write task has a model answer that passes its rubric
python tool/meaning/check_model_answers.py --answers new.json   # check a batch of proposed answers before applying them
python tool/meaning/check_model_answers.py --answers new.json --apply   # write them into the bundles' empty `accepted` lists; then bump contentVersion
python tool/meaning/quantize_model.py --source onnx/model.onnx  # rebuild assets/models/ from the published float model
```

`check_model_answers.py` mirrors the evaluator's word-boundary keyword match
(`_mentionsKeyword`) so an author sees what the Dart gate
(`test/content/levels/level_answerable_test.dart`) will say, without a
Flutter run. The gate is what counts.

The similarity thresholds the app maps a cosine through
(`sentence_similarity.dart`, 0.35 → 0, 0.75 → 1) were set on 2026-10-22 from
the shipped int8 model: unrelated A1/A2 sentences scored 0.0–0.25, an echo
of the partner's line about 0.5–0.57, the same thing in other words
0.68–0.94. The model does not see a wrong word ("my bag is red" for "big",
0.67) or a negation ("I don't like" for "I like", 0.83) — which is why the
signal only adjusts the rubric's score within a bound and never replaces it.
