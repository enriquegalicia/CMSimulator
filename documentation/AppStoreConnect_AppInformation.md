# App Store Connect — App Information

This is the companion to `GameCenter_Setup.md`: everything needed to fill in
App Store Connect's **App Information**, **Pricing and Availability**, and
first-version fields, so the only one left incomplete isn't Game Center.
Values below are either already fixed by the project (cite the source) or
flagged as a decision only Enrique can make — nothing here is guessed.

## Already fixed by the project — just copy these in

| Field | Value | Source |
|---|---|---|
| Bundle ID | `com.aguach1leLabs.CriticalPath` | `CMSimulator.xcodeproj/project.pbxproj` |
| Team | `M4T54FHTC9` | `project.pbxproj` (`DEVELOPMENT_TEAM`) |
| App Name | `Critical Path` | `CMSimulator/Info.plist` (`CFBundleDisplayName`) |
| Version (first submission) | `1.0` | `Info.plist` (`CFBundleShortVersionString`) |
| Build | `1` | `Info.plist` (`CFBundleVersion`) |
| Export Compliance | No encryption beyond what iOS provides — answered automatically | `Info.plist` (`ITSAppUsesNonExemptEncryption = false`); App Store Connect reads this key and should not re-prompt |
| App Store languages | English, Spanish | `Localizable.xcstrings`, 813/813 keys translated in both |
| Privacy Policy URL | `https://enriquegalicia.github.io/Aguach1leLabs-pages/criticalpath/privacy.html` | Added 2026-10-01, matches `PrivacyInfo.xcprivacy` (no tracking, no data collected) |
| Support URL | `https://enriquegalicia.github.io/Aguach1leLabs-pages/criticalpath/support.html` | Added 2026-10-01, same pattern as every other Aguach1leLabs app |
| Marketing URL (optional) | `https://enriquegalicia.github.io/Aguach1leLabs-pages/criticalpath/marketing.html` | Added 2026-10-01 |

> These three pages did not exist until now — every other Aguach1leLabs app
> has a `support.html` / `privacy.html` / `marketing.html` pair in
> `Aguach1leLabs/docs/<app>/` and `Aguach1leLabs-pages/<app>/`; Critical Path
> had none. Both copies must stay identical — `Aguach1leLabs-pages` is the
> one actually deployed to GitHub Pages (`enriquegalicia/Aguach1leLabs-pages`,
> no CNAME, so it serves at the default `github.io` URL above); `docs/` in
> the main Aguach1leLabs repo is the source copy that travels with the
> portfolio. Push `Aguach1leLabs-pages` before submitting, or the URLs above
> 404.

## Recommended, grounded in a decision already made this project

| Field | Recommendation | Why |
|---|---|---|
| Primary Category | **Games → Simulation** | Confirmed 2026-09-23: "game" is the chosen positioning over a training-tool framing. Simulation is the closest Apple category to a profit-driven business sim. |
| Secondary Category | **Games → Strategy**, or **Business** if a second category is wanted | Either is defensible; Strategy fits the decision-making core, Business fits the subject matter. Pick one if offered — not required. |
| Age Rating | Likely **4+** | Scanned `SimEvent.swift` and the trading/worker models for anything rating-relevant: one mild incident (`warehouseInjury`, text only — "Someone was hurt handling stock. Work stopped for the investigation.") and no graphic violence, no gambling mechanics (financial risk-taking in the economy is not Apple's "Simulated Gambling" category, which targets casino-style wagering), no horror, no mature or suggestive themes, no alcohol/tobacco/drug references found anywhere in the content. Answer "None" or "Infrequent/Mild" on every questionnaire category — the injury line is the only one worth a second look, and it is text-only, not depicted. |
| Content Rights | **No** (does not contain, show, or access third-party content) | All art is originally generated for this app (`Scripts/generate_art.py`, `generate_leaderboard_art.py`) per [[art_pipeline_aguachilelabs_style]] |

## Drafted copy — ready to paste, confirm before using

Nothing here has been checked against App Store search-volume data; it is a
reasoned first draft, not ASO research.

**Subtitle** (30 char max): `Build. Grow. Trade. Profit.` (27 chars)

**Promotional Text** (170 char max — the only field editable without a new
build, so it's fine to change this often):

```
Three businesses, one brutal economy. Build buildings, grow a startup, or import and resell — profit is the only score that means anything.
```

(141 chars)

**Description** (4,000 char max):

```
Critical Path is a business decision simulator built around one idea: every shortcut has a real cost, and profit is the only number that tells you whether you found it before it found you.

Play three completely different businesses, each with its own economy:

• Construction — deliver a building against a fixed budget and a hard deadline, with a crew that gets paid whether or not they have work to do.
• Startup — take a company from nothing to an exit, where every funding round dilutes you and every customer you don't go acquire never shows up on its own.
• Import & Resale — buy low, sell high, and discover that cheap suppliers, big upfront orders, and heavy ad spend are usually how you lose.

Six capability levers — Planning, Procurement, Quality, Risk, Communications, Training — behave completely differently in each scenario. Compare your results on a dedicated leaderboard per scenario, built on profit so a building, a software company, and a trading operation are never ranked against each other on the same board.

No subscriptions, no in-app purchases, no accounts. Play in English or Spanish.
```

**Keywords** (100 char max, comma-separated, no spaces after commas —
avoids repeating words already in the app name or subtitle, which Apple
indexes separately):

```
business simulation,tycoon,construction game,startup,economy,strategy,management,import,trading
```

(95 chars)

**Copyright** (200 char max): `© 2026 Enrique Galicia` — confirm this is the
actual rights holder; use `© 2026 Aguach1leLabs` instead if that is a
registered entity rather than a brand name over Enrique's own work.

## The "Prepare for Submission" page, field by field

Grounded directly in Enrique's own Version 1.0 draft (reviewed 2026-10-01),
not guessed from a generic ASC template.

| Field | Status |
|---|---|
| Screenshots — iPhone 6.5" (**Required**) | **Missing — blocks submission.** Needs up to 3 App Previews and 10 screenshots at 1242×2688, 2688×1242, 1284×2778, or 2778×1284px. Only the **first 3** screenshots appear on the install sheet, so lead with the three that sell the game fastest — e.g. a mid-run board, the debrief/profit screen, and the scenario picker. This needs a built app on a real device or simulator at that size; not something this document can produce. |
| Screenshots — iPad, Apple Watch | Not required (iPhone 6.5" is the only tab marked Required in the draft). Skip unless an iPad-specific layout is worth showing separately. |
| Promotional Text / Description / Keywords | Drafted above — paste in. |
| Support URL / Marketing URL | Already covered above — the three new pages. |
| Version | `1.0`, already correct. |
| Copyright | Drafted above — confirm the rights holder. |
| Routing App Coverage File | **Leave empty.** Only for apps that add routes to Apple Maps. Not applicable here. |
| App Clip | Draft correctly shows **No** — nothing to do, the app has no App Clip. |
| iMessage App | Not applicable — no iMessage extension exists. |
| App Icon | Already set (shown as "icon" in the draft) — no action. |
| Game Center section — **verify this** | The draft shows the linked record as App Name `CriticalPathSim`, type iOS App, earliest compatible version `1.0`. That name is a holdover from before the app was renamed to Critical Path (see `GameCenter_Setup.md`'s note on the bundle ID changing three times) and does **not** need to match the current App Store name. What matters is that this record corresponds to bundle ID `com.aguach1leLabs.CriticalPath` — if Game Center still doesn't work after everything in `GameCenter_Setup.md` checks out, confirm this is the right linked record and not a stale one from an earlier bundle ID. |
| App Review Information — Sign-In required | Should be **off/No**. The app has no accounts or login of any kind — toggling this on without credentials to provide would give App Review nothing to sign in with. |
| App Review Information — Contact Information | Already filled in the draft (name, phone, email) — no action needed. |
| App Review Information — Notes (4,000 char max, optional but worth using) | Drafted below — paste in. Heads off the two things most likely to confuse a reviewer. |
| App Store Version Release | **Needs Enrique's decision — do not leave on the draft's default.** The draft shows an automatic release scheduled for "Oct 1, 2026 12:00 PM," which reads like today's date filled in as a placeholder rather than a deliberate choice. Pick **Manually release this version** unless there's a specific reason to want it live the instant Apple approves it. |

**App Review Notes** (4,000 char max):

```
Critical Path has no account system and no in-app purchases — everything is available immediately. To see Game Center leaderboards during review, sign in to a Sandbox Apple Account from the device's Settings app first; otherwise leaderboard submission silently no-ops by design (see in-app Settings → Diagnostics → Game Center for status). An insolvent (bankrupt) run does not post a score — that is intentional, not a bug; deliver a run to see a leaderboard submission.
```

## What this does not cover

- **Game Center setup** — see `GameCenter_Setup.md`, the five leaderboard
  boards and their IDs.
- **ASO keyword research** — the keyword draft above is reasoned, not
  validated against real App Store search-volume data.
- **Screenshots and preview video** — the one remaining hard blocker for
  submission; needs a built app on a device or simulator, which this
  document cannot produce.
