# Bundled models

## all-MiniLM-L6-v2 (sentence embedding)

- `all-MiniLM-L6-v2-int8.onnx` — the `sentence-transformers/all-MiniLM-L6-v2`
  model (Nils Reimers et al., Apache License 2.0), exported to ONNX and
  quantized to 8-bit weights with ONNX Runtime's dynamic quantization
  (`tool/meaning/quantize_model.py`). 384-dimensional embeddings; the app
  mean-pools `last_hidden_state` over the attention mask and L2-normalises.
- `all-MiniLM-L6-v2-vocab.txt` — its uncased WordPiece vocabulary (30,522
  entries), unchanged.

Used by `OnnxMeaningSignalService` (ADR 0013) to measure how close a free
answer is in meaning to a task's model answers, entirely on the device.
Source: the ONNX export published by Chroma
(`https://chroma-onnx-models.s3.amazonaws.com/all-MiniLM-L6-v2/onnx.tar.gz`),
itself from the Hugging Face repository `sentence-transformers/all-MiniLM-L6-v2`.

Licence: Apache License 2.0 — <https://www.apache.org/licenses/LICENSE-2.0>.

## MobileBERT uncased MNLI (`nli/`)

`nli/model.onnx` is `onnx/model_quantized.onnx` of
[Xenova/mobilebert-uncased-mnli](https://huggingface.co/Xenova/mobilebert-uncased-mnli),
an int8 ONNX export of
[typeform/mobilebert-uncased-mnli](https://huggingface.co/typeform/mobilebert-uncased-mnli),
which is Google's MobileBERT fine-tuned on the Multi-Genre Natural Language
Inference corpus. MobileBERT and the fine-tune are released under the Apache
License 2.0. The app uses the model to decide, per rubric group, whether a
learner's answer says what the group means (ADR 0014); its `vocab.txt` and
`config.json` travel with it. Nothing is sent anywhere.
