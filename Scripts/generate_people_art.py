#!/usr/bin/env python3
"""Generate portraits and supplier marks for CMSimulator.

Shares generate_art.py's STYLE_PREAMBLE so everything reads as one
visual family, but writes into Assets.xcassets as imagesets rather than
as loose files. The asset catalog is a folder reference in the Xcode
project, so new art is picked up without touching project.pbxproj -
loose PNGs would each need four pbxproj entries.

Portraits are deliberately neutral: no hard hats, no headsets, no
scenario props. One pool has to serve a building site, a software team
and a trading desk, and scenario-specific props in a shared pool is the
same cross-scenario bug we have already fixed twice in text.

Requires OPENAI_API_KEY (BYOK, real per-image spend).
"""
import argparse, base64, json, os, sys, time, urllib.request, urllib.error
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from generate_art import STYLE_PREAMBLE, call_openai  # one style, one place

REPO_ROOT = Path(__file__).resolve().parents[1]
ASSETS = REPO_ROOT / "CMSimulator" / "Assets.xcassets"

PORTRAIT_STYLE = """
Subject: a head-and-shoulders portrait of one person, facing forward,
friendly and composed, cropped close inside the plate. No hat, no helmet,
no headset, no tools, no background scene - just the person. %s
""".strip()

# Varied on age, build, hair, skin tone and eyewear so a roster of a
# dozen people never looks like one person recoloured.
PORTRAITS = [
    "A young woman with dark curly hair pulled back into a puff, small round earrings, smiling.",
    "A middle-aged man, bald on top, with a full grey beard and heavy eyebrows.",
    "An older woman with short silver hair and rectangular glasses, a serious set to her mouth.",
    "A young man with straight black hair parted to one side and a thin moustache.",
    "A woman with a long dark braid worn over one shoulder, calm expression.",
    "A broad-shouldered man with a shaved head and a thick square beard, no smile.",
    "A young woman with a short blonde bob and large round glasses, freckles across the nose.",
    "A man with thinning combed-over hair and a bushy moustache, tired eyes.",
    "A young woman with tightly coiled natural hair worn very short, wide open smile.",
    "A man with wavy shoulder-length hair and a neatly trimmed beard.",
    "An older man with a thick white walrus moustache and bushy white eyebrows.",
    "A woman with straight shoulder-length black hair and a blunt fringe, neutral expression.",
    "A young man with tousled messy hair and thick black-framed glasses.",
    "A woman with hair in a tight high bun and long hoop earrings.",
    "A young man with a high fade haircut and a small pointed chin beard.",
    "A woman wearing a plain headscarf tied at the back, gentle smile.",
    "A man with a receding hairline and small round wire glasses, raised eyebrow.",
    "A young woman with a very short pixie cut and a nose stud.",
    "An older man with white hair combed straight back and deep smile lines.",
    "A young woman with long loose wavy hair falling past the shoulders.",
    "A man with hair gathered in a topknot and a full beard.",
    "A woman with cropped grey-streaked hair and strong cheekbones.",
    "A young man with short hair and a broad grin showing teeth.",
    "A woman with thick dark eyebrows and hair tucked behind both ears.",
]

# Supplier marks: one per trade and one per sourcing origin, so a
# surveyor's letterhead never sits on an order for rebar.
BRANDS = [
    ("BrandSurveying", "An abstract company mark: a surveyor's tripod simplified to three legs under a small circular lens."),
    ("BrandStructural", "An abstract company mark: a capital I-beam cross-section beside a short length of ribbed reinforcing bar."),
    ("BrandEngineering", "An abstract company mark: a setsquare overlapping a small stamped approval seal."),
    ("BrandBuilders", "An abstract company mark: three stacked bricks with a trowel resting across the top one."),
    ("BrandMechanical", "An abstract company mark: a pipe elbow joint crossed with a small valve wheel."),
    ("BrandElectrical", "An abstract company mark: a plug prong shape inside a simplified lightbulb outline."),
    ("BrandFactoryChina", "An abstract company mark: a simplified factory roofline with three chimneys above a shipping container."),
    ("BrandResellerChina", "An abstract company mark: a small parcel box with a fast motion swoosh behind it."),
    ("BrandFactoryVietnam", "An abstract company mark: a simplified low factory building beside a single tall palm frond."),
    ("BrandFactoryIndia", "An abstract company mark: a simplified export crate stamped with a circular seal."),
    ("BrandDistributorDomestic", "An abstract company mark: a delivery van silhouette beside a small stacked pallet."),
]


def write_imageset(name: str, png_bytes: bytes) -> Path:
    folder = ASSETS / f"{name}.imageset"
    folder.mkdir(parents=True, exist_ok=True)
    (folder / f"{name}.png").write_bytes(png_bytes)
    (folder / "Contents.json").write_text(json.dumps({
        "images": [
            {"filename": f"{name}.png", "idiom": "universal", "scale": "1x"},
            {"idiom": "universal", "scale": "2x"},
            {"idiom": "universal", "scale": "3x"},
        ],
        "info": {"author": "xcode", "version": 1},
    }, indent=2) + "\n")
    return folder


def targets(which):
    out = []
    if which in ("all", "portraits"):
        for i, subject in enumerate(PORTRAITS, start=1):
            out.append((f"Portrait{i:02d}", PORTRAIT_STYLE % subject))
    if which in ("all", "brands"):
        for name, subject in BRANDS:
            out.append((name, f"Subject: {subject}"))
    return out


def main():
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("--set", default="all", choices=["all", "portraits", "brands"])
    ap.add_argument("--only", help="Comma-separated asset names to regenerate.")
    ap.add_argument("--missing-only", action="store_true", help="Skip assets already present, so a resumed run costs nothing for what it already has.")
    ap.add_argument("--dry-run", action="store_true", help="Print prompts and the cost estimate. Spends nothing.")
    ap.add_argument("--size", default="1024x1024")
    ap.add_argument("--api-key")
    args = ap.parse_args()

    jobs = targets(args.set)
    if args.only:
        wanted = set(args.only.split(","))
        jobs = [j for j in jobs if j[0] in wanted]
    if args.missing_only:
        jobs = [j for j in jobs if not (ASSETS / f"{j[0]}.imageset" / f"{j[0]}.png").exists()]

    if args.dry_run:
        for name, subject in jobs:
            print(f"would generate -> Assets.xcassets/{name}.imageset")
        print(f"\n{len(jobs)} images · gpt-image-1 1024x1024 high ≈ ${len(jobs) * 0.167:.2f}")
        return

    key = args.api_key or os.environ.get("OPENAI_API_KEY")
    if not key:
        print("error: no API key. Set $OPENAI_API_KEY. Nothing was generated.", file=sys.stderr)
        sys.exit(1)

    made = 0
    for name, subject in jobs:
        prompt = f"{STYLE_PREAMBLE}\n\n{subject}"
        print(f"generating -> {name} ...", end=" ", flush=True)
        png = None
        for attempt in range(4):
            try:
                png = call_openai(prompt, key, args.size)
                break
            except urllib.error.HTTPError as e:
                detail = e.read().decode("utf-8", errors="replace")[:160]
                if e.code in (429, 500, 502, 503, 504) and attempt < 3:
                    time.sleep(4 * (attempt + 1)); continue
                print(f"FAILED ({e.code}): {detail}")
                break
            except Exception as e:
                # Network blips are common on long runs; back off and retry.
                if attempt < 3:
                    time.sleep(4 * (attempt + 1)); continue
                print(f"FAILED: {e}")
        if png is None:
            continue
        write_imageset(name, png)
        made += 1
        print("done")
    print(f"\n{made}/{len(jobs)} written. Rebuild so the catalog is recompiled.")


if __name__ == "__main__":
    main()
