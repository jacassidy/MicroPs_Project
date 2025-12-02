#!/usr/bin/env python3
"""
make_font8x16_hex.py

Offline helper to generate font8x16.hex for font_rom_8x16.sv.

You must first download fontlist.js manually from:
  GitHub repo susam/pcface -> out/modern-dos-8x16/fontlist.js
and save it as 'fontlist.js' in the same directory as this script.
"""

import re
from pathlib import Path

IN_FILE = Path("fontlist.js")
OUT_FILE = Path("font8x16.hex")

if not IN_FILE.exists():
    raise SystemExit(
        f"ERROR: {IN_FILE} not found.\n"
        "Download 'fontlist.js' from the susam/pcface repo and place it here."
    )

print(f"Reading {IN_FILE} ...")
text = IN_FILE.read_text(encoding="utf-8")

# Extract all 0xNN values from the JS array.
# Each glyph = 16 rows; expect 256 glyphs => 4096 integers total.
hex_tokens = re.findall(r"0x([0-9a-fA-F]{1,2})", text)
rows = [int(h, 16) for h in hex_tokens]

if len(rows) % 16 != 0:
    raise SystemExit(
        f"ERROR: Expected groups of 16 rows, got {len(rows)} rows. "
        "Is this the correct fontlist.js?"
    )

num_glyphs = len(rows) // 16
print(f"Found {num_glyphs} glyphs of 16 rows each")

if num_glyphs != 256:
    print("WARNING: Expected 256 glyphs (CP437); "
          f"actual count is {num_glyphs}. Proceeding anyway.")

print(f"Writing {OUT_FILE} ...")
with OUT_FILE.open("w", encoding="ascii") as f:
    for r in rows:
        f.write(f"{r:02x}\n")

print("Done.")
print("Place font8x16.hex where your simulator/synth can see it.")
