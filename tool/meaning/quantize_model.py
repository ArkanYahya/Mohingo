"""Produce the bundled embedding model from the published ONNX export.

  python -m pip install onnx onnxruntime
  python tool/meaning/quantize_model.py --source /path/to/onnx/model.onnx

Writes assets/models/all-MiniLM-L6-v2-int8.onnx (8-bit weights, dynamic
quantization, about 23 MB from the 90 MB float model) and copies the
vocabulary beside it. The source is the ONNX export of
sentence-transformers/all-MiniLM-L6-v2 (Apache 2.0) — see
assets/models/NOTICE.md for where it comes from. Re-run only to change the
model; the output is committed.
"""
import argparse
import shutil
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / "assets/models"


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--source", required=True, help="the float model.onnx; vocab.txt is read from the same folder")
    a = ap.parse_args()
    from onnxruntime.quantization import QuantType, quantize_dynamic

    source = Path(a.source)
    OUT.mkdir(parents=True, exist_ok=True)
    target = OUT / "all-MiniLM-L6-v2-int8.onnx"
    quantize_dynamic(str(source), str(target), weight_type=QuantType.QInt8)
    shutil.copyfile(source.parent / "vocab.txt", OUT / "all-MiniLM-L6-v2-vocab.txt")
    print(f"{target.name}: {target.stat().st_size / 1e6:.1f} MB")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
