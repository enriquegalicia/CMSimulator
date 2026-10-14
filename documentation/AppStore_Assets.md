# App Store assets: Critical Path

Portfolio rules, specs and workflow: `Aguach1leLabs/APP_STORE_ASSETS.md` (in the main
Aguach1leLabs repo; this app lives in its own repo). Upload-ready files go in
[store-assets/](store-assets/), one folder per slot. Check them from the Aguach1leLabs repo:
`python3 scripts/store_assets.py check "/Users/aguachile/Desktop/DEVELOPMENTS/CMSimulator"`.

**State (2026-10-06):** 1.0 was rejected for 4.3 alongside PepperTalk (same template); see [AppReview_Uniqueness.md](AppReview_Uniqueness.md). Screenshots are being captured by this repo's own script (see Capture below). The target is `TARGETED_DEVICE_FAMILY = "1,2"`, so **iPhone 6.3" and iPad 13" are both required** ([AppStoreConnect_AppInformation.md](AppStoreConnect_AppInformation.md) was updated to match on 2026-10-06). Header art is done (`store-assets/creative/header.png`, isometric low-poly diorama). The search asset renders from the cached background once `iphone-6.3` lands.

## Screenshot story

Up to three can appear in search on their own, so 1-3 must explain the product without help.

1. **01-board**: a mid-run board, decisions, cash and the clock
2. **02-debrief**: the profit debrief, what each shortcut cost
3. **03-picker**: the three scenarios (Construction, Startup, Import & Resale)
4. 04-trading
5. 05-growth
6. 06-levers: the six capability levers
7. 07-hiring
8. 08-suppliers
9. 09-risk
10. 10-log

**Capture:** owned by this repo's own `Scripts/capture_screenshots.sh` (build flag
`STORE_SCREENSHOTS`, `-StoreShot <id>` stages a real run; signed without the Game Center
entitlement so a fresh simulator doesn't show the GC sign-in). It writes
`store-assets/{iphone-6.3,iphone-6.9,ipad-13}/{en,es}-NN-<id>.png`. Don't use the portfolio's
generic `capture_screens.py` here. Once `iphone-6.3` exists, render the search asset with
`python3 scripts/creative_assets.py ~/Desktop/DEVELOPMENTS/CMSimulator --only search` from the
Aguach1leLabs repo. That uses the cached background, so no new AI cost.

## On-image text

| # | EN | ES |
|---|---|---|
| 1 | Every shortcut has a real cost | Cada atajo tiene un costo real |
| 2 | Profit is the only score | La ganancia es el único marcador |
| 3 | Three businesses, three economies | Tres negocios, tres economías |

## Art spec

Read by `python3 scripts/creative_assets.py "/Users/aguachile/Desktop/DEVELOPMENTS/CMSimulator"` (in the Aguach1leLabs repo). Edit a line, then
re-run: `--force` regenerates the AI art, while the search composite re-renders free from the cached
background. `Search screens` match the upload-ready screenshots by number (`01` → `en-01-*.png`), so
the search asset appears as soon as screenshots exist. Art direction is this app's own; no
sibling uses the same medium ([4.3 rule](https://github.com/enriquegalicia/Aguach1leLabs/blob/main/APP_STORE_ASSETS.md#4-portfolio-rule-creative-assets-are-43-surface-too)).

- **Header prompt:** Wide isometric low-poly 3D diorama of three small businesses side by side on one floating island: a construction site with a crane and an orange hard hat on a beam, a tiny startup office with glowing screens, and a warehouse with crates and a truck, all connected by a glowing green node-and-line path (a critical path) that runs through the centre. Clean, strategic, game-like. The path's central node sits in the central 60%. No text, letters, numbers, logos, phones or UI anywhere.
- **Search background prompt:** Soft isometric low-poly terrain in warm greys and greens with tiny crates and trees only at the outer edges and corners. The top third and the centre must stay calm and nearly empty so a headline and phone screenshots can sit there. No text, letters, numbers, logos, phones or UI anywhere.
- **Search screens:** 01, 02, 03
- **Search headline:** en = Every shortcut has a real cost | es = Cada atajo tiene un costo real
- **Ink:** #1A1C20
- **Font:** SFNS.ttf Condensed Black

## Product Page Optimization

Rules: [APP_STORE_ASSETS.md §6](https://github.com/enriquegalicia/Aguach1leLabs/blob/main/APP_STORE_ASSETS.md#6-product-page-optimization-ppo-ab-test-the-default-page).
Starts once a version is approved and live. One test at a time, up to 90 days.

**Test 1: Board vs debrief.** Is a mid-run board (it's a game) or the profit debrief (the stakes) the stronger opener? Use 2 treatments at 50% traffic (25% each), in every language the
page has.

- **Original:** a mid-run board
- **Treatment A** (`store-assets/ppo/a-debrief-first/`): the profit debrief first
- **Treatment B** (`store-assets/ppo/b-scenarios-first/`): the three-scenario picker first

Apply a winner only at 90% confidence. **Next test:** captions on vs off the first three
screenshots. An icon test needs the alternate icon shipped in a build first (§6).

**Results log:** none yet.

## Custom Product Pages

Rules: [APP_STORE_ASSETS.md §7](https://github.com/enriquegalicia/Aguach1leLabs/blob/main/APP_STORE_ASSETS.md#7-custom-product-pages-cpp-one-page-per-audience-or-keyword-cluster).
In App Store Connect: *Custom Product Pages → +*. Choose **Copy Existing Product Page** and use
Reference Name `Critical Path · <slug> · <audience>`. Files go in `store-assets/cpp/<slug>/<slot>/`.
Each keyword can belong to only one page.

| Slug | Audience · keywords | First screenshot | Promo text | Deep link |
|---|---|---|---|---|
| `tycoon` | Tycoon / business sim players · business simulator, tycoon game | the scenario picker | Build, grow a startup or trade goods: three economies, one score, profit.<br>ES: Construye, haz crecer una startup o comercia: tres economías, un solo marcador, la ganancia. | opens the picker |
| `students` | Business and project-management students · project management game, business strategy | the capability levers | Learn how planning, quality and risk really trade off by running a business.<br>ES: Aprende cómo se equilibran planeación, calidad y riesgo dirigiendo un negocio. | opens Construction |

## Watch-outs

- Every asset must be 4+, with no prices, URLs, ©, Apple awards, other platforms or competitor names.
- 4.3: this was rejected as template output. The header and search art must look nothing like PepperTalk's or any sibling's.
- The incident text ("Someone was hurt handling stock") is fine in-app, but never on an image.
- No real company names or logos in the demo businesses.
