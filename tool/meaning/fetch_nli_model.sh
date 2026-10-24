#!/usr/bin/env sh
# Fetches the natural-language-inference model behind the per-part meaning
# signal (ADR 0014) into assets/models/nli/, from Hugging Face. Run it from
# any machine that can reach huggingface.co, then commit the three files.
#
#   sh tool/meaning/fetch_nli_model.sh
#
# The repository: Xenova/mobilebert-uncased-mnli (MobileBERT fine-tuned on
# MNLI by typeform, int8 ONNX by Xenova; Apache-2.0). To try another
# WordPiece NLI model in the Transformers.js layout, pass its repo:
#
#   sh tool/meaning/fetch_nli_model.sh Xenova/distilbert-base-uncased-mnli
set -eu
REPO="${1:-Xenova/mobilebert-uncased-mnli}"
BASE="https://huggingface.co/$REPO/resolve/main"
DEST="$(cd "$(dirname "$0")/../.." && pwd)/assets/models/nli"
mkdir -p "$DEST"
fetch() {
  echo "fetching $1 -> $2"
  curl -fL --retry 3 -o "$DEST/$2.part" "$BASE/$1"
  mv "$DEST/$2.part" "$DEST/$2"
}
fetch onnx/model_quantized.onnx model.onnx
fetch vocab.txt vocab.txt
fetch config.json config.json
echo
echo "done: $(du -h "$DEST"/model.onnx | cut -f1) model, labels $(python3 -c "import json,sys; print(json.load(open('$DEST/config.json'))['id2label'])" 2>/dev/null || echo '(see config.json)')"
echo "now: git add assets/models/nli && git commit"
