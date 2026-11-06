# Critical Path — answers to App Review's 4.3 / 4.2.6 questions

**Round 2, written 2026-10-15.** Build 2 was rejected again under **4.3(a), 4.3(b) and 4.2.6**
with the same nine-question template (FidgetLog got the same message the same day). Apple's
note says a resubmission without substantial improvements will be rejected again, so
**build 3** changes what the reviewer sees and does, not only the words. The portfolio-wide
rules live in `Aguach1leLabs/APP_REVIEW_4_3_GUARD.md`. Round 1 (build 2's reply and fixes) is
kept at the end of this file.

## What the reviewer most likely saw in build 2

| Seen in review | Why it reads as template or spam | Build 3 |
|---|---|---|
| Stock iOS everywhere: system-blue buttons, grouped settings lists, a segmented control, white in light mode, no accent colour at all (the project had no AccentColor) | The default SwiftUI look is what generated and template apps look like ("overall design and user experience", App Review's follow-up of 2026-10-13) | **Own design**: slate planning-sheet background with a drafting grid, one signal-lime colour reserved for the critical path, amber for money out, condensed headings, custom board tabs. Every sheet uses it. Launch screen matches |
| First screen: "New run", a grouped form whose footer said "Every scenario runs on the same simulation" | Reads as one game reskinned three times: 4.3(b) | **Designed title screen** over the game's own art; each business card says how money arrives in it; the footer now says each business has its own work, money, risks and leaderboard |
| An app called *Critical Path* with no critical path anywhere | Name and content don't match; nothing a tycoon game doesn't have | **Path board**: a live schedule of every work stream, the critical path in lime, float on the others, deadline and today, payment milestones certified vs. paid, and a card that names what sets the finish date with a one-tap fix |
| "Earned, not yet paid" as a single number | The app's core lesson had no picture | **Cash curve**: money out vs. money in (and earned incl. not yet paid), daily, on the first tab and in the debrief |
| Support and Privacy URLs (`enriquegalicia.github.io/Aguach1leLabs-pages/criticalpath/…`) | **They return 404**: the pages were never pushed to the live repo (checked 2026-10-15) | Pages restyled and copied into `Aguach1leLabs-pages`; **push before resubmitting** |
| Icon in the cream-plate, brown-outline sticker style shared by the account's other apps | The account's visual fingerprint (`review_gate.py` flags it as the retired sticker template) | **Your decision**, see "Before you send" |

## What changed in build 1.0 (3)

| Change | What it does | Where |
|---|---|---|
| **Path board** (new tab) | One bar per stream on a day axis: solid = built, outline = forecast at the crew's real pace, hatched = planned (no crew yet). The critical path is lime; every other stream shows its float ("+12d"). Today, the deadline and the forecast finish are drawn across it. A card names what sets the finish date (no crew, waiting on materials, can't start until N%, or simply no float) and offers "Hire for …" / "Order for …". Startup and import runs show the launch / first-sales date instead, and the season peak when Demand planning is staffed | `Engine/Schedule.swift`, `Views/ScheduleBoardView.swift` |
| **Payments on the timeline** | Each progress payment's certified day against the day its money lands, history or projection, with the current payment lag | same |
| **Cash curve** | Money out, money in, earned incl. not yet paid, one point a day; the caption says how big the funding gap is | `Views/CashCurveView.swift`, `SimulationEngine.recordCashPoint()` |
| **Debrief** | "Your cash curve" for the whole run and "Your critical path" as the run left it, with one sentence on what set the end date | `Views/ResultView.swift` |
| **HUD forecast** | "ETA day N" now comes from the same schedule, so the header and the Path board never disagree. The planning assumption was calibrated against played runs (mean error ~11% on days 25 and 40) and is locked by a test | `ScheduleTuning`, `testTheForecastTracksWhatActuallyHappens` |
| **Own visual design** | `Views/Theme.swift`; AccentColor asset; every sheet; launch screen | — |
| **Title screen** | Replaces the grouped form | `Views/ScenarioPickerView.swift` |
| **How to play** | New section: reading the Path and the cash curve, in all three scenarios | `Views/HelpView.swift` |

All new text in English and Spanish (73 new strings). 140 unit tests green (7 new). Build
number 3. Store screenshots recaptured (iPhone 6.3" and iPad 13", EN + ES); the Path board is
shot #2, so it shows in search results.

## Before you send

1. **Push the web pages.** `Aguach1leLabs-pages/criticalpath/` exists only on your Mac (the
   live Support and Privacy URLs return 404). The files are copied there; commit and push that
   repo, then open both URLs in a browser. A missing privacy policy alone is a rejection
   (guideline 5.1.1).
2. **The icon.** The current icon is the cream-plate sticker style the account's other apps
   used, which App Review has now seen across several rejected apps. On 2026-10-14 an
   isometric-island icon with a lime critical path was generated (commit `1505936`) and then
   reverted. It matches build 3's new look (same slate and lime). To use it:
   `git checkout 1505936 -- CMSimulator/Assets.xcassets/AppIcon.appiconset`. Your call; the
   reply below is true either way.
3. **Check the facts in the reply:** answer 5 lists the apps on your account (make it match
   App Store Connect → Apps exactly); answer 4's "about 70 iterations since August 2026" is from
   round 1; answer 9 says the 2015 CMSimulator was yours, not MAG Architecture's.
4. **One record per app.** If an older record of this game (CMSimulator, CriticalPathSim)
   still exists in My Apps and was never released, remove it (round 1, step 1).
5. Don't submit another new app while this and FidgetLog are in review.

## Order of operations

1. Push the pages (above). Decide the icon.
2. Archive and upload **1.0 (3)**.
3. In App Store Connect: subtitle **"Cash-flow business simulator"**, the new description,
   promotional text, keywords and screenshots
   ([AppStoreConnect_AppInformation.md](AppStoreConnect_AppInformation.md),
   [AppStore_Assets.md](AppStore_Assets.md)); paste the **App Review notes** below.
4. Reply in the **Resolution Center** with the reply below.
5. Select build 3 and **Submit for Review**; log it in `Aguach1leLabs/SUBMISSIONS.md`.
6. If the same template comes back, don't resubmit: appeal to the App Review Board
   (developer.apple.com/contact/app-store/?topic=appeal) with this reply. The binary shares
   no code with any other app, which is the strongest fact in an appeal.

## Reply to paste (Resolution Center, 3,860 characters)

```
Thank you for the review. Rather than resubmit the same app, I made substantial changes in build 3. The answers to all nine questions follow.

What changed in build 3
- The game is now built around what its name promises: a live critical-path schedule. A new Path board draws every work stream on a day axis, highlights the critical path, shows each stream's float and names what is setting the finish date, with the action that would move it.
- Progress payments sit on the same timeline: the day each is certified against the day its money actually lands.
- A cash curve, on the main board and in the end-of-run debrief, plots money out against money in, day by day.
- Its own visual design replaced the stock iOS forms: a slate planning-sheet look with one signal colour for the critical path, and a designed title screen that explains how money arrives in each business.

1. Critical Path is a business-operations simulator about cash flow and schedule. The player runs a business day by day; every decision (hiring, firing, buying inputs and when, quality, risk cover, training, client and investor relations) moves money through a real cash-flow model, scored only on profit. It teaches what people usually learn by losing money: payments arrive behind the work, payroll comes before income, idle crews cost full wages, defects cost far more at handover, and a business can be profitable on paper and still run out of cash. The three scenarios are separate economic models: a fixed-price construction contract paid by milestone with retention; a startup paid by customers, with dilutive funding and an exit priced on growth; and an import business with marketplace fees, duty, seasonal demand and delayed payouts.

2. Architects, construction and project managers, engineers and small-business owners in the Americas (English and Mexican Spanish), students of construction management and entrepreneurship, and strategy players who want an economy with real cause and effect.

3. Business games on the App Store are mostly tycoon and idle games where money accrues automatically and nothing models when cash actually arrives; real project-management simulations are licensed desktop products for classrooms. Critical Path is a short, bilingual mobile game whose board is made of the tools a project manager actually uses: a critical-path schedule with float, a payment schedule and a cash curve.

4. The game was tested by playing it throughout development (about 70 iterations since August 2026), and balance is checked by an automated harness that plays many strategies over many random seeds. Changes made from that testing include: hiring was a free speed boost and became a daily wage with onboarding drag; the startup scenario was rebuilt around customers, churn, funding and an exit after play showed it behaved like construction; runs are saved the moment they end; and the new schedule's forecast was calibrated against played runs.

5. It is a standalone product. My account's other apps (PepperTalk, KeepChallengeIt, TheLuckyNumber, SharedNapkin, SteadyMind, YourMindSpark and FidgetLog) cover speaking practice, fitness, a number picker, sketching, cognitive exercises, puzzles and a virtual pet; Critical Path is the only simulation or business app.

6. No. None of my other apps deals with business, money or scheduling, so none could host it, and its three scenarios are already consolidated in this one app.

7. No shared code, frameworks or assets. The binary uses only Apple frameworks (SwiftUI, SwiftData, Swift Charts, GameKit) and about 13,000 lines of Swift written for this app; all artwork was made for it.

8. No third-party SDK, template, engine or content library is used.

9. No. It was not made for a client. I created the original CMSimulator in 2015 and rewrote it from scratch in 2026; it is published under my own account.
```

## App Review notes (paste into App Review Information → Notes)

```
Critical Path is a cash-flow and scheduling simulator with three scenarios, each its own economic model (construction contract, software startup, import & resale). No account or purchase is needed.

A 2-minute path to what is unique:
1. First launch opens the "New run" screen. Keep Construction selected and tap Start. A one-time briefing opens; close it with Done.
2. On the Site tab, tap Hire on the Design card and pick anyone, then press Play (▶). The Cash curve card starts drawing money out against money in, day by day.
3. Open the Path tab: every work stream on a day axis, the critical path in lime, float on the others, the deadline, and each progress payment's certified day against the day it is paid. The card under the chart names what is setting the finish date and offers the fix (for example "Hire for Structure").
4. Open Levers and tap Staff on Planning to turn the rough plan into a forecast.
5. Fast-forward (the last transport button) to the end: the debrief shows the run's cash curve, its final critical path and a full P&L.
6. Start a Startup or Import run from the scenario chip at the top-left to see the other two economies.

Game Center: on a device without a Game Center account, iOS shows its own sign-in sheet at launch; it can be dismissed. Leaderboards need a Sandbox Apple Account. An insolvent run doesn't post a score; this is intentional.
```

## The nine answers, one by one

Same content as the reply, kept under the standard headings.

### 1. What the app does and the problem it solves

A business-operations simulator about cash flow and schedule, scored only on profit, with three
separate economic models (milestone-paid construction contract with retention; customer-paid
startup with dilutive funding and a growth-priced exit; import business with marketplace fees,
duty, seasonal demand and delayed payouts). It teaches what people usually learn by losing
money, and since build 3 it shows it with a project manager's tools: a critical-path schedule
with float, a payment timeline and a cash curve.

### 2. Intended user

Architects, construction and project managers, engineers and small-business owners in the
Americas (English and Mexican Spanish), construction-management and entrepreneurship students,
and strategy players who want real cause and effect.

### 3. The gap it fills

Tycoon and idle games accrue money automatically and never model when cash arrives; real
project simulations are licensed desktop products for classrooms. Critical Path is a short,
bilingual mobile game whose board is the schedule and the cash curve.

### 4. Beta testing

Developer play-testing throughout development (about 70 iterations since August 2026) and an
automated harness over many strategies and seeds. Applied: hiring became a daily wage with
onboarding drag; the startup scenario was rebuilt; runs save the moment they end; the schedule
forecast was calibrated against played runs. If an external TestFlight round runs, add it here.

### 5. Standalone product or part of a suite

Standalone. The account's other apps (PepperTalk, KeepChallengeIt, TheLuckyNumber,
SharedNapkin, SteadyMind, YourMindSpark, FidgetLog) cover speaking practice, fitness, a number
picker, sketching, cognitive exercises, puzzles and a virtual pet.

### 6. Could it be an in-app purchase in another app?

No. No other app deals with business, money or scheduling; the three scenarios are already in
this one app.

### 7. Shared code, frameworks or assets with my other apps

None. Apple frameworks only (SwiftUI, SwiftData, Swift Charts, GameKit), about 13,300 lines of
Swift written for this app, all artwork made for it. `similarity_audit` (2026-10-13): 2% of lines
in common with any sibling, clean project lineage.

### 8. Shared code or content with third-party apps

No third-party SDK, template, engine or content library.

### 9. Built for a client or third party?

No. The original CMSimulator (2015) and this 2026 rewrite are the developer's own, published
under the developer's own account.

---

## Round 1 (build 2, 2026-10-06): kept for the record

### What the reviewer most likely saw

Apple doesn't say which of the three clauses triggered. These are the
things a reviewer could see, from the binary and from the account:

| Seen by the reviewer | Why it reads as spam or template | Status |
|---|---|---|
| The developer account (team `M4T54FHTC9`) holds 27+ bundle IDs. Seven new apps were submitted between late August and early October, some at poc/prototype maturity | 4.3 is judged per account as well as per app. A high-volume account gets its next submission questioned before anyone opens it | Account level: see `APP_REVIEW_4_3_GUARD.md` |
| First launch opened a plain iOS settings-style form (system blue, SF Symbols, no art) that read "Both run on the same simulation" over **three** scenarios | Looks like an unfinished template | **Fixed in build 2** |
| The picker advertised "the design firm scenario, which is not built yet" | A placeholder for missing content, in a submitted build | **Fixed in build 2**: removed |
| "How to play" explained building contracts even in a Startup or Import run | Looks like one game reskinned three times, which is exactly 4.3(b) | **Fixed in build 2**: each scenario has its own briefing, opened automatically the first time it's played |
| Help said a run ends after two missed payrolls; the engine ends it after four | Sloppiness | **Fixed in build 2** |
| Launch screen was hard-coded white, so it flashed on dark-mode devices | Sloppiness | **Fixed in build 2**: follows the system background |
| App Review notes only talked about Game Center sandbox setup | Gave the reviewer no path to the unique part of the app | **Rewritten below** |
| Possibly older app records for the same app (`com.magarchitecture.CMSimulator`, `com.aguach1leLabs.CMSimulator`, the `CriticalPathSim` record) | Several records for one app is 4.3(a) duplication | ⚠️ **Check in App Store Connect** (step 1 below) |

On a fresh install with no Game Center account, iOS shows its own
"Sign In to Game Center" sheet before the app's first screen. That comes
from the OS for any app with the Game Center entitlement. The app does
not trigger it, cannot suppress it, and it is not a 4.3 issue.

### Order of operations

1. **Clean up App Store Connect.** Look in My Apps for any record other
   than *Critical Path* that is this same game (CMSimulator,
   CriticalPathSim). If one was never released, remove it (App
   Information → Remove App). If one *was* released, stop: the right
   move is to ship Critical Path as an **update to that record**, not as
   a new app. A second listing of the same app is 4.3(a) by definition.
2. **Run a short TestFlight beta before replying** (question 4 is the
   weakest answer today). Five to ten people from your architecture or
   construction network, one week, one feedback form. Record who tested,
   what they said, and what you changed. Even one real change from real
   feedback is worth more than any wording.
3. **Reply in the Resolution Center first** with the reply below, after
   going through "Check before sending". Never send a claim you can't
   back up; Apple can and does ask follow-up questions. The rejection says that if the app already meets the
   guidelines, you should answer rather than resubmit.
4. **Upload build 2** (version 1.0, build 2: already bumped in
   `Info.plist`) so it's processed and ready. It carries the fixes above.
5. **Submit build 2 once App Review answers** (or straight away if they
   ask for changes), with the new App Review notes and refreshed
   screenshots (see the end of this file). Log the submission in
   `Aguach1leLabs/SUBMISSIONS.md`.

Do **not** create a new bundle ID or a new app record to get around the
rejection. That is the one move that turns a rejection into an account
problem.

---

### Check before sending (these notes are not part of the reply)

Everything inside the reply block below is a finished statement, safe to
paste as-is. Before pasting, confirm these facts are true. If one isn't,
edit or delete that sentence:

- **(5)** SharedNapkin, Challenger, PepperTalk, SteadyMind and
  YourMindSpark are all on your account (live or submitted).
- **(9)** The 2015 CMSimulator was yours, not made for or owned by MAG
  Architecture or anyone else. If it was, rewrite (9) to say who owns it
  now.
- **(4)** If you run a TestFlight beta first, you can add a sentence with
  its real numbers. The reply is complete without one.

### Reply to paste (3,451 characters, under the 4,000 limit)

```
Thank you for the review. I believe Critical Path meets guidelines 4.3 and 4.2.6, and I have prepared build 2 with first-run fixes. (1) Critical Path is a business-operations simulator. The player runs a business day by day, and every decision (hiring, firing, buying inputs and when, quality, risk cover, training, dealing with the client, investors or buyers) moves money through a real cash-flow model, scored only on profit. It teaches the cash-flow mechanics people usually learn by losing money: payment retentions, payroll due before income arrives, the cost of idle staff, defects that cost far more at handover, and working capital locked in stock. Its three scenarios are separate economic models, not reskins. Construction: a fixed-price contract, milestone payments that arrive behind the work, retention, crews paid while waiting on materials, and onboarding drag. Startup: no sales before launch, word-of-mouth growth, rising acquisition cost, churn from tech debt, dilutive funding, and an exit priced on growth. Import & Resale: a marketplace fee stack based on published fee structures, duty and exchange-rate exposure, seasonal demand, delayed payouts and ageing stock. Each has its own incidents, leaderboard and end-of-run debrief itemising where the money went. (2) Users: architects, construction and project managers, engineers and small-business owners in the Americas (the app is in English and Mexican Spanish), students of construction management and entrepreneurship, and strategy players who want an economy with real cause and effect. (3) Gap: business games on the App Store are mostly tycoon and idle games where money accrues automatically and nothing models when cash actually arrives, while real project-management simulations are mostly licensed desktop products for classrooms and companies. Critical Path is a short, mobile, bilingual game built on the mechanics that sink real businesses: payment lag, insolvency while profitable on paper, extra people making a late job later, inventory ageing and returns. (4) Testing: the game was tested by playing it throughout development (about 70 iterations since August 2026), and balance was verified with an automated harness that plays many strategies over many random seeds. Changes made from that testing: Hiring was a free speed boost and became a daily wage with onboarding drag. The startup scenario was rebuilt around customers, churn, funding and an exit after play showed it behaved like construction. Runs are now saved the moment they end. (5) It is a standalone product. My account's other apps (such as SharedNapkin, Challenger, PepperTalk, SteadyMind and YourMindSpark) cover sketching, fitness, speaking practice and puzzles; Critical Path is the only simulation or business app. (6) No. None of my other apps deals with business or money, so none could host it, and its three scenarios are already consolidated in one app. (7) No shared code, frameworks or assets. The binary uses only Apple frameworks (SwiftUI, SwiftData, GameKit) and about 11,700 lines of Swift written for this app. All artwork was made for it; only the icon's illustration style resembles my other apps. (8) No third-party SDK, template, engine or content library is used. (9) No. It was not made for a client. I created the original CMSimulator in 2015 and rewrote it from scratch in 2026, and it is published under my own account. Happy to provide anything else that would help.
```

---

### New App Review notes (paste into App Review Information → Notes)

```
Critical Path is a business-operations simulator with three scenarios that each run a different economic model (construction contract, software startup, import & resale). No account or purchase is needed.

A 2-minute path to the core of the game:
1. On first launch, pick a scenario and tap Start. A short briefing for that scenario opens automatically.
2. On a Construction run: tap Hire on the Design card, tap Order to buy materials, then press Play. Watch Cash fall daily while money arrives only when milestones are certified ("earned, not yet paid").
3. Open Levers to staff Planning or Quality, then the Log to see incidents and their cost.
4. Fast-forward (>> or >|) to the end for the debrief, which itemises where every peso went.
5. Start a Startup or Import run from the scenario selector at the top-left to see the different models.

Game Center: on a device without a Game Center account, iOS shows its own sign-in sheet at launch; it can be dismissed. Leaderboards need a Sandbox Apple Account. An insolvent run doesn't post a score; this is intentional.
```

⚠️ Before pasting, walk through these five steps on a real build. Every
tap above must match the button labels exactly. If one doesn't, fix the
note, not the reviewer's expectations.

### Listing changes worth making before resubmitting

- **Screenshots:** lead with what no tycoon game shows. Suggested order:
  1. the cash-out/cash-in strip with "earned, not yet paid";
  2. the end-of-run debrief cost breakdown;
  3. the three-scenario picker;
  4. the import fee stack;
  5. the startup customer curve.

  Put a short caption on each that states the mechanic ("Paid behind the
  work, not when you spend").
- **Subtitle:** "Build. Grow. Trade. Profit." could describe any tycoon
  game. A subtitle that names the difference, e.g. *"Cash-flow business
  simulator"*, is both a better 4.3(b) signal and a better keyword.
- **Description:** keep the current draft. It already describes specific
  mechanics. Remove anything that sounds like generic marketing.
