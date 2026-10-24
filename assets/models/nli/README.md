# The natural-language-inference model (ADR 0014)

This folder holds the on-device model that reads a learner's free answer part
by part: MobileBERT fine-tuned on MNLI, quantized to int8, as converted for
Transformers.js by Xenova (`Xenova/mobilebert-uncased-mnli` on Hugging Face;
the original is `typeform/mobilebert-uncased-mnli`). Three files:

| File | What | Size |
|---|---|---|
| `model.onnx` | `onnx/model_quantized.onnx` from the repository | ~25 MB |
| `vocab.txt` | the WordPiece vocabulary | ~230 KB |
| `config.json` | the model configuration; `id2label` names the three classes | ~1 KB |

They are fetched with `tool/meaning/fetch_nli_model.sh` from a machine that
can reach Hugging Face, then committed. Without them the app still runs:
`OnnxEntailmentModel` reports itself unavailable and the meaning signal falls
back to the similarity over model answers (ADR 0013). Licence: Apache-2.0
(MobileBERT and the typeform fine-tune); see `../NOTICE.md`.
