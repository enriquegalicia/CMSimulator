#!/usr/bin/env python3
"""Generate Critical Path's app icon via OpenAI's image API.

**Art direction changed 2026-10-13.** The old icon (a hard hat on a
winding path, in the Aguach1leLabs cream-plate sticker style) was retired:
App Review rejected Critical Path and PepperTalk under guideline 4.3 /
4.2.6, partly because the account's apps shared one look, and the
sticker template was that look (Aguach1leLabs' APP_REVIEW_4_3_GUARD.md).
A hard hat also said "construction" when the game has three businesses.

The new icon uses the app's own direction, the same as its App Store
header (documentation/store-assets/creative/header.png): an isometric
low-poly floating island crossed by a glowing signal-lime critical path.
Slate night background and signal lime #7CFF5B are used by no other app
on the account.

This app's AppIcon.appiconset uses the older multi-file Contents.json
format (a real, physically-present PNG per size/scale pair, not the
modern single-1024-source format) - so after regenerating icon-1024.png,
this script also re-derives every smaller size from it via `sips`.
Skipping that step is exactly how the icon went stale before: only
icon-1024.png (the App Store marketing slot) got regenerated while
icon-120.png/icon-180.png/etc (what the home screen and Settings
actually display) kept shipping the old artwork silently - the build
doesn't warn about this since every filename Contents.json expects
was still present on disk, just outdated.

Requires OPENAI_API_KEY in the environment (BYOK - your own key for a
one-time dev-tooling cost, never shipped in the app).
"""
import argparse
import base64
import json
import os
import subprocess
import sys
import urllib.request
import urllib.error
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parents[1]
APPICONSET = REPO_ROOT / "CMSimulator" / "Assets.xcassets" / "AppIcon.appiconset"
TARGET = APPICONSET / "icon-1024.png"
CONTENTS_JSON = APPICONSET / "Contents.json"
API_URL = "https://api.openai.com/v1/images/generations"

ACCENT_HEX = "#7CFF5B"  # signal lime, Critical Path only

PROMPT = f"""
A modern app icon, square 1:1, filling the whole canvas edge to edge
with no border, frame, rounded plate or margin. Background: deep slate
night blue (#16202C) with a very soft radial lift behind the centre.
Centre, large and cropped in close: one small isometric low-poly 3D
floating island block, viewed from above at a 3/4 angle, with faceted
grassy green top and rocky brown faceted underside. Across its top runs
one bold glowing signal-lime ({ACCENT_HEX}) path: three bright round
nodes joined by a thick glowing line that turns once, rising from the
front-left corner to the back-right corner like a schedule's critical
path. Behind the last node stands one tiny yellow tower crane. Simple,
chunky shapes that stay readable at small sizes, soft studio lighting,
crisp facets, one gentle lime glow around the path and nothing else.
No text, letters, numbers, people, hard hats or logos.
""".strip()


def regenerate_smaller_sizes():
    """Re-derive every other icon file in Contents.json from the freshly
    written 1024x1024 master via `sips`, so no size is left stale."""
    with open(CONTENTS_JSON) as f:
        contents = json.load(f)

    for image in contents["images"]:
        filename = image["filename"]
        if filename == TARGET.name:
            continue
        width_pt = float(image["size"].split("x")[0])
        scale = int(image["scale"].rstrip("x"))
        pixels = round(width_pt * scale)
        out_path = APPICONSET / filename
        subprocess.run(
            ["sips", "-z", str(pixels), str(pixels), str(TARGET), "--out", str(out_path)],
            check=True, capture_output=True,
        )
        print(f"  -> {filename} ({pixels}x{pixels})")


def call_openai(prompt, api_key):
    body = json.dumps({
        "model": "gpt-image-2",
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
    # App Store Connect refuses an icon with any alpha channel, even an
    # opaque one, and the image API can return RGBA.
    from PIL import Image
    Image.open(TARGET).convert("RGB").save(TARGET)
    print("done")
    print("Regenerating smaller sizes from the new master via sips:")
    regenerate_smaller_sizes()
    print("Rebuild in Xcode so the asset catalog picks up the new files.")


if __name__ == "__main__":
    main()
