#!/usr/bin/env python3
"""Generate the leaderboard images App Store Connect asks for.

Game Center requires one image per leaderboard. Apple's spec: 512x512 or
1024x1024, PNG or JPEG, RGB, flattened, no alpha and no rounded corners
(Game Center masks them itself). gpt-image-1 emits 1024x1024 opaque PNGs,
which satisfies all of that.

These are *App Store Connect* assets, not app resources - they are
uploaded by hand and never ship inside the bundle - so they are written
to documentation/leaderboard-art/ rather than into Assets.xcassets.

Shares STYLE_PREAMBLE with the in-game art so the boards look like the
game they belong to.
"""
import argparse, os, sys, time, urllib.error
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from generate_art import STYLE_PREAMBLE, call_openai

REPO_ROOT = Path(__file__).resolve().parents[1]
OUT = REPO_ROOT / "documentation" / "leaderboard-art"

BOARDS = [
    ("profit-construction", "A rising bar chart made of three stacked bricks, with a small hard hat resting on the tallest bar, representing profit earned building."),
    ("profit-startup", "A rising line chart breaking upward out of a rounded app window, with a small rocket nose at the line's tip, representing a company growing in value."),
    ("profit-importing", "A shipping container with a rising arrow emerging from its open door and a small coin at the arrow's tip, representing margin earned reselling."),
    ("costmaster", "A pair of balance scales with a stack of coins on one pan and a small brick on the other, representing cost kept under control."),
    ("timemaster", "A stopwatch with a small calendar page behind it and a checkmark on the dial, representing finishing ahead of the date."),
]


def main():
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("--dry-run", action="store_true", help="Print prompts and the cost estimate. Spends nothing.")
    ap.add_argument("--missing-only", action="store_true", help="Skip images already on disk.")
    ap.add_argument("--only", help="Comma-separated names.")
    ap.add_argument("--size", default="1024x1024")
    ap.add_argument("--api-key")
    args = ap.parse_args()

    jobs = BOARDS
    if args.only:
        wanted = set(args.only.split(","))
        jobs = [j for j in jobs if j[0] in wanted]
    if args.missing_only:
        jobs = [j for j in jobs if not (OUT / f"{j[0]}.png").exists()]

    if args.dry_run:
        for name, _ in jobs:
            print(f"would generate -> documentation/leaderboard-art/{name}.png")
        print(f"\n{len(jobs)} images · gpt-image-1 1024x1024 high ≈ ${len(jobs) * 0.167:.2f}")
        return

    key = args.api_key or os.environ.get("OPENAI_API_KEY")
    if not key:
        print("error: no API key. Set $OPENAI_API_KEY. Nothing was generated.", file=sys.stderr)
        sys.exit(1)

    OUT.mkdir(parents=True, exist_ok=True)
    made = 0
    for name, subject in jobs:
        prompt = f"{STYLE_PREAMBLE}\n\nSubject: {subject}"
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
                if attempt < 3:
                    time.sleep(4 * (attempt + 1)); continue
                print(f"FAILED: {e}")
        if png is None:
            continue
        (OUT / f"{name}.png").write_bytes(png)
        made += 1
        print("done")

    print(f"\n{made}/{len(jobs)} written to documentation/leaderboard-art/")
    print("Upload each in App Store Connect under the matching leaderboard's Localization.")


if __name__ == "__main__":
    main()
