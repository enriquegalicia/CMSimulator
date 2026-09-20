# Game Center — leaderboard configuration

This document is the configuration contract between the app and App Store
Connect. `CMSimulatorTests.LeaderboardTests` reads this file and fails if
the app submits to a board that is not listed here, so the two cannot
drift apart.

> **Bundle ID:** `com.aguach1leLabs.CriticalPath`
>
> It changed three times during development (`com.magarchitecture.CMSimulator`,
> then `com.aguach1leLabs.CMSimulator`, then the current one). Leaderboards
> registered under an older ID belong to a different app record and do not
> carry over.
>
> **The board IDs were wrong until 2026-09-20.** They were prefixed
> `com.aguach1leLabs.CriticalPathSim.` — the *Xcode target* name — while
> the app ships as `com.aguach1leLabs.CriticalPath`. If you created boards
> following the bundle-ID convention, nothing the app submitted could ever
> match them, and the failure is silent. Every ID below is now aligned to
> the real bundle ID, and a test enforces it. **If you already created
> boards under the `…CriticalPathSim…` prefix, they are orphaned — create
> the ones below instead.**

## What the app does automatically

Authentication, submission on every completed run, and the in-app
dashboard button are all done in `GameCenterManager.swift`. Nothing below
can be done from code — leaderboards exist only in App Store Connect.

Submissions happen when the player saves a result. **Only delivered runs
are submitted**; an insolvent run has no profit worth ranking. A
submission to a board that does not exist yet fails silently and is
logged, so shipping before these are configured is safe — scores simply
do not appear.

## The five leaderboards

Create each at **App ▸ Critical Path ▸ Features ▸ Game Center ▸
Leaderboards ▸ +**, as a **Classic** leaderboard. Copy the IDs — do not
retype them. A typo produces no user-facing error, only a line in the
device log.

### Profit, one per scenario — sort **High to Low**

Profit is the only metric every scenario shares. A building, a software
company and a trading operation are not comparable on one ranking, so
each gets its own board. This mirrors the in-app boards, which have
always been filtered by scenario.

| Leaderboard ID | Reference name | Sort | Score format |
|---|---|---|---|
| `com.aguach1leLabs.CriticalPath.profit.construction` | Construction Profit | **High to Low** | Money |
| `com.aguach1leLabs.CriticalPath.profit.startup` | Startup Profit | **High to Low** | Money |
| `com.aguach1leLabs.CriticalPath.profit.importing` | Import Profit | **High to Low** | Money |

The submitted value is `RunResult.score`, rounded to a whole number:
profit, multiplied by the difficulty multiplier (Steady 0.8, Standard 1.0,
Tight 1.35), then by the venture setup factor (startup and import only —
lean opening capital and no grace period score above 1.0), then by 1.1 if
the run finished on time. Never negative; a loss-making delivery posts 0.

### Cost and time — construction only, sort **Low to High**

Submitted **only for construction runs**. "Built it for less" and "built
it in fewer days" rank coherently against a fixed scope and a contractual
deadline. They do not for a startup, whose length is a strategic choice,
or for an import season, whose length is fixed by the calendar.

| Leaderboard ID | Reference name | Sort | Score format |
|---|---|---|---|
| `com.aguach1leLabs.CriticalPath.costmaster` | Cost Master | **Low to High** | Money |
| `com.aguach1leLabs.CriticalPath.timemaster` | Time Master | **Low to High** | Elapsed time — see note |

- **Cost Master** submits `RunResult.costs.total`, rounded — every peso
  spent, all sixteen cost lines.
- **Time Master** submits **days × 10**, so the board has tenth-of-a-day
  precision. Configure the score format so the value reads correctly:
  either a custom format showing one decimal, or Integer with the
  understanding that 1,412 means 141.2 days.

> **Sort order defaults to High to Low in App Store Connect.** The three
> profit boards want that default. The two ascending boards must be
> changed — they are "lower is better," the opposite of a points board.

### Retired — do not create

`com.aguach1leLabs.CriticalPath.constructionmaster` was a combined
ascending cost-plus-days score. It has no code path any more and posting
profit to an ascending board would rank the worst runs first. If it was
already created, leave it unused or delete it.

## Localization

Each board needs at least one **Leaderboard Localization** (display name
and score format). The app ships English and Spanish, so add both:

| Board | English | Spanish |
|---|---|---|
| Construction Profit | Construction — Profit | Construcción — Utilidad |
| Startup Profit | Startup — Profit | Startup — Utilidad |
| Import Profit | Import & Resale — Profit | Importación — Utilidad |
| Cost Master | Cost Master | Maestro del Costo |
| Time Master | Time Master | Maestro del Tiempo |

Set the currency on the four Money-formatted boards to match what players
actually see; the app's display currency is configurable in Settings, so
pick the one your primary market uses and accept that the board's unit is
fixed while the in-app figure is not.

## Local scores are separate and already work

The in-app boards (trophy icon) are SwiftData, not Game Center. They
persist every saved run with its scenario, difficulty, persona, seed and
full result, and filter by scenario. They work offline, with no Apple
account, and are unaffected by anything in this document.

## How to test this properly

Game Center reports submission failures nowhere a player can see, so
"scores are not appearing" has several possible causes that look
identical. Work through these in order — each step rules one out, and
you should not move on until the current one passes.

Game Center does not authenticate meaningfully in the Simulator, so all
of this happens on a real device.

### Step 1 — Are you signed in?

Settings ▸ Game Center on the device, signed into a **Sandbox Apple
Account**. Then in the app: **Settings ▸ Diagnostics ▸ Game Center**. The
first row must show your player alias, not "No".

If it says No, nothing else can work. Sign in and relaunch.

### Step 2 — Do the boards actually exist?

Same panel, tap **Check the boards exist**. This asks Game Center which
of the five IDs are registered. It posts no score, so run it as often as
you like.

- All five **Registered and reachable** → configuration is correct, go to
  step 3.
- Any **Not registered in App Store Connect** → that board has not been
  created, or its ID does not match character-for-character. This is the
  most common cause by far. Copy the ID from the table above; do not
  retype it.

Do not proceed until all five are green. Playing runs against
unregistered boards tells you nothing.

### Step 3 — Does a real run post?

1. Play **construction** to a delivered finish (an insolvent run is never
   submitted — that is deliberate, not a bug).
2. Save the result.
3. Return to **Diagnostics ▸ Game Center**. The construction profit board
   should now read **Last score sent: …**, and Cost Master and Time Master
   should too.
4. Tap the trophy in-app to open the Game Center dashboard and confirm
   the score is visible there.

If the panel shows a **failure message** instead, that is the real
GKError — it will name the actual problem.

### Step 4 — Does each scenario reach its own board?

1. Play **import & resale** to a finish and save.
2. In the panel, `profit.importing` should update and
   `profit.construction` should be unchanged.
3. Cost Master and Time Master should also be unchanged — they take
   construction runs only, by design.

That last check is the one that proves the boards are genuinely separated
rather than all fed from one place.

### Step 5 — Export if it still fails

Diagnostics ▸ share. The export includes the Game Center health line and
every submission attempt with its error, which is what to send on if the
problem is not obvious from the panel.

Boards work in Sandbox and TestFlight as soon as they are created, before
the app is live.

## If scores do not appear

- Check the IDs match exactly — this is the most common failure, and it
  is silent.
- Confirm Game Center is enabled for this app in App Store Connect, not
  just the `com.apple.developer.game-center` entitlement in Xcode.
- Look for `Game Center score submission failed` in the device console;
  `GameCenterManager.submit(_:to:)` logs the underlying `GKError` there.
- Remember insolvent runs are never submitted. Deliver a run to test.
