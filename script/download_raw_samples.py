#!/usr/bin/env python3
"""Fetch the fixed CC0 camera-validation corpus, verifying every SHA-256."""
import concurrent.futures
import hashlib
import json
from pathlib import Path
import urllib.request

ROOT = Path(__file__).resolve().parent.parent
DESTINATION = ROOT / ".fixtures" / "raw"
DESTINATION.mkdir(parents=True, exist_ok=True)
SAMPLES = json.loads((ROOT / "Docs" / "raw-samples.json").read_text())


def download(sample):
    target = DESTINATION / sample["file"]
    if target.exists() and hashlib.sha256(target.read_bytes()).hexdigest() == sample["sha256"]:
        return sample["file"] + " cached"
    temporary = target.with_suffix(target.suffix + ".download")
    for attempt in range(3):
        try:
            digest = hashlib.sha256()
            with urllib.request.urlopen(sample["url"], timeout=60) as source, temporary.open("wb") as output:
                while chunk := source.read(1024 * 1024):
                    output.write(chunk)
                    digest.update(chunk)
            if digest.hexdigest() != sample["sha256"]:
                raise ValueError("SHA-256 mismatch: " + sample["file"])
            temporary.replace(target)
            return f'{sample["camera"]}: {sample["file"]} ({target.stat().st_size // 1048576} MiB) verified'
        except Exception:
            temporary.unlink(missing_ok=True)
            if attempt == 2:
                raise


if __name__ == "__main__":
    with concurrent.futures.ThreadPoolExecutor(max_workers=3) as pool:
        for result in pool.map(download, SAMPLES):
            print(result, flush=True)
