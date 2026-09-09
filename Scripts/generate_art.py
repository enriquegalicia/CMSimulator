#!/usr/bin/env python3
"""Generate CMSimulator's in-game card art via OpenAI's image API.

Extends generate_icon.py's pattern to the work-stream and capability
card images plus the intro screen's logo. Same tooling logic, same
Aguach1leLabs family style (cream plate, espresso-brown ink outline,
terracotta primary, green accent) so every card in the game reads as
one visual family instead of the original 2015-era stock photography.

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
GAME_DIR = REPO_ROOT / "CMSimulator"
API_URL = "https://api.openai.com/v1/images/generations"

ACCENT_HEX = "#3DAA6E"

STYLE_PREAMBLE = f"""
A flat vector sticker illustration, square 1:1 crop, matching an existing
icon family. A rounded-square backing plate in warm cream (#F6E8D3),
inset slightly from the edge, outlined in a thick, uniform espresso-brown
ink stroke (#4A2F1C) - the same outline weight and color used on every
shape inside it. Flat color fills only: warm terracotta orange (#D9722C)
as the primary fill, {ACCENT_HEX} as the one secondary accent color, both
outlined in the same espresso-brown ink stroke as the plate. One soft,
subtle highlight ellipse on the main rounded surface - no other
gradients, no photorealism, no drop shadows, no text or lettering.
Hand-crafted, warm, a little naive - like a kitchen-market sticker, not
a corporate tech logo. Centered composition, confident scale, cropped in
close so the subject nearly touches the plate's edges.
""".strip()

# (output filename relative to CMSimulator/, subject prompt)
IMAGES = [
    ("Design.png", "A drafting compass and a rolled-up blueprint with a pencil crossed over it, representing architectural design."),
    ("Structure.png", "A steel I-beam frame with a plumb bob hanging from it, representing structural engineering."),
    ("Engineering.png", "A gear interlocking with a slide rule / setsquare, representing engineering calculations."),
    ("Construction.png", "A hard hat resting on a stack of bricks with a trowel, representing active construction."),
    ("IHS.png", "A water droplet and a safety shield combined, representing hydraulic/sanitary and fire-alarm building systems."),
    ("IES.png", "A lightning bolt inside a lightbulb outline, representing electrical and lighting building systems."),
    ("Planning.png", "A calendar page with a checkmark and a small clock hand, representing project planning and scheduling."),
    ("Procurement.png", "A shipping box with a handshake symbol above it, representing vendor sourcing and procurement."),
    ("Quality.png", "A magnifying glass over a checkmark badge, representing quality control and inspection."),
    ("Risk.png", "A shield with a small warning triangle at its center, representing risk management."),
    ("Communications.png", "A speech bubble overlapping a second speech bubble, representing stakeholder communications."),
    ("Training.png", "An open book with a graduation-cap silhouette above it, representing workforce training."),
    # Startup scenario work streams. Same six capability cards are reused
    # across scenarios, so only the work streams need their own art.
    ("Discovery.png", "A magnifying glass held over a sticky-note board of small squares, representing user research and product discovery."),
    ("Platform.png", "Three stacked server or database slabs with a small foundation block beneath them, representing a core platform."),
    ("API.png", "Two puzzle-like connector blocks clicking together with a small data arrow between them, representing an API and data layer."),
    ("Features.png", "A stack of app window cards fanned out, the top one showing a checkmark, representing shipped product features."),
    ("Payments.png", "A credit card overlapping a small receipt with a coin, representing payments and billing."),
    ("Launch.png", "A small rocket lifting off from a rounded pad with a checklist clipboard beside it, representing launch readiness."),
]

LOGO = ("AppIcon-Source.png", "Three interlocking gears - the largest containing a small money bag with a dollar sign, the second a lightbulb, the third a crossed hammer and wrench - representing cost, ideas, and construction.")


def call_openai(prompt, api_key, size):
    body = json.dumps({
        "model": "gpt-image-1",
        "prompt": prompt,
        "size": size,
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
    parser.add_argument("--dry-run", action="store_true", help="Print prompts without calling the API or spending money.")
    parser.add_argument("--only", help="Comma-separated list of output filenames to regenerate (default: all).")
    parser.add_argument("--size", default="1024x1024", help="Image size for the card art (default 1024x1024 - gpt-image-1 only supports 1024x1024, 1024x1536, 1536x1024, or auto).")
    args = parser.parse_args()

    targets = IMAGES + [LOGO]
    if args.only:
        wanted = set(args.only.split(","))
        targets = [t for t in targets if t[0] in wanted]
        if not targets:
            print(f"error: none of {sorted(wanted)} matched a known image name", file=sys.stderr)
            sys.exit(1)

    if args.dry_run:
        for filename, subject in targets:
            print(f"would generate -> CMSimulator/{filename}")
            print(f"prompt:\n{STYLE_PREAMBLE}\n\nSubject: {subject}\n")
        return

    api_key = args.api_key or os.environ.get("OPENAI_API_KEY")
    if not api_key:
        print("error: no API key. Set $OPENAI_API_KEY or pass --api-key. Nothing was generated.", file=sys.stderr)
        sys.exit(1)

    for filename, subject in targets:
        prompt = f"{STYLE_PREAMBLE}\n\nSubject: {subject}"
        target = GAME_DIR / filename
        print(f"generating -> {target.relative_to(REPO_ROOT)} ...", end=" ", flush=True)
        try:
            png_bytes = call_openai(prompt, api_key, args.size)
        except urllib.error.HTTPError as e:
            print(f"FAILED ({e.code}): {e.read().decode('utf-8', errors='replace')[:300]}")
            continue
        except Exception as e:
            print(f"FAILED: {e}")
            continue
        target.write_bytes(png_bytes)
        print("done")

    print("Rebuild in Xcode so the bundle picks up the new files.")


if __name__ == "__main__":
    main()
