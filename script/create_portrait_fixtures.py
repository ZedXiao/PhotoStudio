#!/usr/bin/env python3
"""Derive orientation-only test copies from the fixed CC0 Sony ARW sample."""
from pathlib import Path
import struct

ROOT = Path(__file__).resolve().parent.parent
source = ROOT / ".fixtures/raw/2414.arw"
original = source.read_bytes()
order = "<" if original[:2] == b"II" else ">"
assert struct.unpack_from(order + "H", original, 2)[0] == 42
offset = struct.unpack_from(order + "I", original, 4)[0]
count = struct.unpack_from(order + "H", original, offset)[0]
orientation_offset = None
for index in range(count):
    position = offset + 2 + index * 12
    tag, kind, length = struct.unpack_from(order + "HHI", original, position)
    if tag == 0x112:
        assert kind == 3 and length == 1
        orientation_offset = position + 8
        break
assert orientation_offset is not None
destination = ROOT / ".fixtures/portrait"
destination.mkdir(parents=True, exist_ok=True)
for orientation in (6, 8):
    data = bytearray(original)
    struct.pack_into(order + "H", data, orientation_offset, orientation)
    target = destination / f"orientation-{orientation}.arw"
    target.write_bytes(data)
    print(target)
