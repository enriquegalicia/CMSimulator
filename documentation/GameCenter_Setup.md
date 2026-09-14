# Game Center — leaderboard configuration

This document is the configuration contract between the app and App Store
Connect. `CMSimulatorTests.LeaderboardTests` reads this file and fails if
the app submits to a board that is not listed here, so the two cannot
drift apart.

> **Bundle ID:** `com.aguach1leLabs.CriticalPathSim`
>
> It changed twice during development (from `com.magarchitecture.CMSimulator`,
> then from `com.aguach1leLabs.CMSimulator`). Leaderboards registered under
> either older ID belong to a different app record and do not carry over.
> This app needs its own App Store Connect record under the current ID,
> with the five boards below created there from scratch.

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
| `com.aguach1leLabs.CriticalPathSim.profit.construction` | Construction Profit | **High to Low** | Money |
| `com.aguach1leLabs.CriticalPathSim.profit.startup` | Startup Profit | **High to Low** | Money |
| `com.aguach1leLabs.CriticalPathSim.profit.importing` | Import Profit | **High to Low** | Money |

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
| `com.aguach1leLabs.CriticalPathSim.costmaster` | Cost Master | **Low to High** | Money |
| `com.aguach1leLabs.CriticalPathSim.timemaster` | Time Master | **Low to High** | Elapsed time — see note |

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

`com.aguach1leLabs.CriticalPathSim.constructionmaster` was a combined
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

## Testing

Game Center does not authenticate meaningfully in the Simulator. On a
real device:

1. Sign into a **Sandbox Apple Account** (Settings ▸ Game Center).
2. Play a run to completion and save the result.
3. Tap the trophy in-app to open the dashboard and confirm the score
   landed on the board for **that scenario**.
4. Play a second scenario and confirm it lands on a *different* board.

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
