# Bundled models

## all-MiniLM-L6-v2 (sentence embedding)

- `all-MiniLM-L6-v2-int8.onnx` — the `sentence-transformers/all-MiniLM-L6-v2`
  model (Nils Reimers et al., Apache License 2.0), exported to ONNX and
  quantized to 8-bit weights with ONNX Runtime's dynamic quantization
  (`tool/meaning/quantize_model.py`). 384-dimensional embeddings; the app
  mean-pools `last_hidden_state` over the attention mask and L2-normalises.
- `all-MiniLM-L6-v2-vocab.txt` — its uncased WordPiece vocabulary (30,522
  entries), unchanged.

Used by `OnnxMeaningSignalService` (ADR 0011) to measure how close a free
answer is in meaning to a task's model answers, entirely on the device.
Source: the ONNX export published by Chroma
(`https://chroma-onnx-models.s3.amazonaws.com/all-MiniLM-L6-v2/onnx.tar.gz`),
itself from the Hugging Face repository `sentence-transformers/all-MiniLM-L6-v2`.

Licence: Apache License 2.0 — <https://www.apache.org/licenses/LICENSE-2.0>.
