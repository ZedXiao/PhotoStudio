#!/usr/bin/env python3
"""Verify both RAW decoding paths against orientation-only CC0 derivatives."""
import json
from pathlib import Path
import subprocess
import sys

ROOT = Path(__file__).resolve().parent.parent
probe = sys.argv[1]
subprocess.run([sys.executable, str(ROOT / "script/create_portrait_fixtures.py")], check=True)
records = []
for force in (False, True):
    for orientation in (6, 8):
        path = ROOT / f".fixtures/portrait/orientation-{orientation}.arw"
        run = subprocess.run([probe, "--worker"] + (["--libraw"] if force else []) + [str(path)], check=True, capture_output=True, text=True, timeout=90)
        record = json.loads(next(line for line in run.stdout.splitlines() if line.startswith("{")))
        assert record["backgroundWorker"] is True
        assert record["rawOrientation"] == orientation
        assert record["height"] > record["width"] and record["thumbnailHeight"] > record["thumbnailWidth"]
        record.pop("path", None)
        records.append(record)
        print(f'{record["file"]} {record["engine"]}: {record["width"]}×{record["height"]}, thumbnail {record["thumbnailWidth"]}×{record["thumbnailHeight"]} PASS', flush=True)
(ROOT / "Docs/portrait-validation.json").write_text(json.dumps(records, ensure_ascii=False, indent=2) + "\n")
