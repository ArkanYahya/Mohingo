"""The per-level manifest the app reads (schema in docs/DATA_MODEL.md)."""
import json
from datetime import datetime, timezone
from pathlib import Path

SCHEMA_VERSION = 1


def load(path: Path) -> dict | None:
    return json.load(open(path, encoding="utf-8")) if path.exists() else None


def build(level_id: str, content_version: str, engine_id: str, speed: float,
          clips: dict[str, dict[str, str]]) -> dict:
    return {
        "schemaVersion": SCHEMA_VERSION,
        "levelId": level_id,
        "contentVersion": content_version,
        "generatedAt": datetime.now(timezone.utc).replace(microsecond=0).isoformat().replace("+00:00", "Z"),
        "engine": {"name": engine_id, "speed": speed},
        "audio": {"container": "m4a", "codec": "aac", "bitrateKbps": 32, "sampleRateHz": 24000, "channels": 1},
        "clips": {k: dict(sorted(v.items())) for k, v in sorted(clips.items())},
    }


def write(path: Path, manifest: dict) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    with open(path, "w", encoding="utf-8", newline="\n") as f:
        json.dump(manifest, f, ensure_ascii=False, indent=1)
        f.write("\n")


def referenced_files(manifest: dict) -> set[str]:
    return {p for roles in manifest["clips"].values() for p in roles.values()}
