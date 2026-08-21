#!/usr/bin/env python3
"""Generate CMSimulator's real app icon via OpenAI's image API.

Same tooling logic as Aguach1leLabs' generate-icons skill
(.claude/skills/generate-icons/generate_icons.py there): calls gpt-image-1
with a prompt matching the Lab's shared icon DNA (see ICON_STYLE_GUIDE.md
in that repo) and drops the resulting 1024x1024 PNG straight into
Assets.xcassets/AppIcon.appiconset/, using the exact filename Contents.json
already expects. This app isn't part of that repo, so it gets its own copy
of the prompt/script rather than editing Aguach1leLabs' shared guide.

Requires OPENAI_API_KEY in the environment (BYOK - your own key for a
one-time dev-tooling cost, never shipped in the app).
"""
import argparse
import base64
import json
import os
import sys
import urllib.request
import urllib.error
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parents[1]
TARGET = REPO_ROOT / "CMSimulator" / "Assets.xcassets" / "AppIcon.appiconset" / "icon-1024.png"
API_URL = "https://api.openai.com/v1/images/generations"

# Green (#3DAA6E) is the Lab's most-shared accent and the closest match to
# the existing gear icon's teal - keeps CMSimulator visually in-family
# without introducing a new accent color.
ACCENT_HEX = "#3DAA6E"

PROMPT = f"""
A flat vector sticker illustration for an iOS app icon, square 1:1 crop.
A rounded-square backing plate in warm cream (#F6E8D3), inset slightly
from the edge, outlined in a thick, uniform espresso-brown ink stroke
(#4A2F1C) - the same outline weight and color used on every shape inside it.

Centered composition: three interlocking gears, cropped in close so they
nearly touch the plate's edges - confident scale, not small or floating.
The largest gear contains a small money bag with a dollar sign, the second
contains a lightbulb, the third contains a crossed hammer and wrench -
representing cost, ideas, and construction. Flat color fills only: warm
terracotta orange (#D9722C) as the primary fill, {ACCENT_HEX} as the one
secondary accent color, both outlined in the same espresso-brown ink stroke
as the plate. One soft, subtle highlight ellipse on the main rounded
surface - no other gradients, no photorealism, no drop shadows, no text or
lettering. Hand-crafted, warm, a little naive - like a kitchen-market
sticker, not a corporate tech logo.
""".strip()


def call_openai(prompt, api_key):
    body = json.dumps({
        "model": "gpt-image-1",
        "prompt": prompt,
        "size": "1024x1024",
        "quality": "high",
        "background": "opaque",
        "n": 1,
    }).encode("utf-8")
    req = urllib.request.Request(API_URL, data=body, method="POST")
    req.add_header("Authorization", f"Bearer {api_key}")
    req.add_header("Content-Type", "application/json")
    with urllib.request.urlopen(req, timeout=120) as resp:
        payload = json.loads(resp.read())
    b64 = payload["data"][0]["b64_json"]
    return base64.b64decode(b64)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--api-key", help="OpenAI API key (defaults to $OPENAI_API_KEY)")
    parser.add_argument("--dry-run", action="store_true",
                         help="Print the prompt without calling the API or spending money.")
    parser.add_argument("--force", action="store_true",
                         help="Overwrite the icon file if it already exists.")
    args = parser.parse_args()

    if args.dry_run:
        print(f"would generate -> {TARGET.relative_to(REPO_ROOT)}")
        print(f"accent: {ACCENT_HEX}")
        print(f"prompt:\n{PROMPT}")
        return

    if TARGET.exists() and not args.force:
        print(f"skip: {TARGET.relative_to(REPO_ROOT)} already exists (use --force to overwrite)", file=sys.stderr)
        sys.exit(1)

    api_key = args.api_key or os.environ.get("OPENAI_API_KEY")
    if not api_key:
        print("error: no API key. Set $OPENAI_API_KEY or pass --api-key. Nothing was generated.", file=sys.stderr)
        sys.exit(1)

    print(f"generating -> {TARGET.relative_to(REPO_ROOT)} ...", end=" ", flush=True)
    try:
        png_bytes = call_openai(PROMPT, api_key)
    except urllib.error.HTTPError as e:
        print(f"FAILED ({e.code}): {e.read().decode('utf-8', errors='replace')[:300]}")
        sys.exit(1)
    except Exception as e:
        print(f"FAILED: {e}")
        sys.exit(1)

    TARGET.write_bytes(png_bytes)
    print("done")
    print("Rebuild in Xcode so the asset catalog picks up the new file.")


if __name__ == "__main__":
    main()
