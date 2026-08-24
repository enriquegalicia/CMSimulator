#!/usr/bin/env python3
"""Generate CriticalPathSim's real app icon via OpenAI's image API.

Same tooling logic as Aguach1leLabs' generate-icons skill
(.claude/skills/generate-icons/generate_icons.py there): calls gpt-image-1
with a prompt matching the Lab's shared icon DNA (see ICON_STYLE_GUIDE.md
in that repo) and drops the resulting 1024x1024 PNG straight into
Assets.xcassets/AppIcon.appiconset/, using the exact filename Contents.json
already expects. This app isn't part of that repo, so it gets its own copy
of the prompt/script rather than editing Aguach1leLabs' shared guide.

The first version of this prompt (three separate gears, each holding its
own unrelated symbol - money bag, lightbulb, wrench+hammer - in four
different fill colors) broke the style guide's core rules: "one bold
central symbol, or a tight 2-3-piece cluster that reads as one graphic
unit" and "never more than 3-4 total fill colors plus the outline." This
version follows the guide's master template exactly instead of
improvising around it.

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

# Green (#3DAA6E) is the Lab's most-shared accent (OverLanded, Sidequest,
# TheRiseTrack, SteadyMind, LotteryLuckyNumbers per ICON_STYLE_GUIDE.md
# section 2) - kept from the first pass rather than introducing a new one.
ACCENT_HEX = "#3DAA6E"

PROMPT = f"""
A flat vector sticker illustration for an iOS app icon, square 1:1 crop.
A rounded-square backing plate in warm cream (#F6E8D3), inset slightly
from the edge, outlined in a thick, uniform espresso-brown ink stroke
(#4A2F1C) - the same outline weight and color used on every shape inside it.

Centered composition, drawn as ONE large, bold, continuous shape filling
nearly the entire plate edge-to-edge - not two separate pieces with empty
space between them: a construction hard hat planted directly on top of a
single thick winding checkpoint path, the path growing straight out from
under the hat's brim like a critical-path diagram, with three small round
checkpoint nodes fused along the path. The hat's brim overlaps the top of
the path so they read as one fused object, scaled up large and confident
so the path's ends and the hat's crown nearly touch the plate's inner
edge on every side - no small or floating elements, no empty margins.
Flat color fills only: warm terracotta orange (#D9722C) as the primary
fill (the hard hat and the path line), {ACCENT_HEX} as the one secondary
accent color (the checkpoint nodes), both outlined in the same
espresso-brown ink stroke as the plate. One soft, subtle highlight
ellipse on the main rounded surface - no other gradients, no
photorealism, no drop shadows, no text or lettering. Hand-crafted, warm,
a little naive - like a kitchen-market sticker, not a corporate tech logo.
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
    print("Regenerating smaller sizes from the new master via sips:")
    regenerate_smaller_sizes()
    print("Rebuild in Xcode so the asset catalog picks up the new files.")


if __name__ == "__main__":
    main()
