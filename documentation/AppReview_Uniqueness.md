# Critical Path — answers to App Review's 4.3 / 4.2.6 questions

Rejected 2026-10 under 4.3(a), 4.3(b) and 4.2.6. This file is the
response plan and the reply text. PepperTalk got the same rejection the
same day. The portfolio-wide rules that keep it from happening again live
in `Aguach1leLabs/APP_REVIEW_4_3_GUARD.md`, and this file follows that
guard's `AppReview_Uniqueness.md` format.

## What the reviewer most likely saw

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

## Order of operations

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

## Check before sending (these notes are not part of the reply)

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

## Reply to paste (3,451 characters, under the 4,000 limit)

```
Thank you for the review. I believe Critical Path meets guidelines 4.3 and 4.2.6, and I have prepared build 2 with first-run fixes. (1) Critical Path is a business-operations simulator. The player runs a business day by day, and every decision (hiring, firing, buying inputs and when, quality, risk cover, training, dealing with the client, investors or buyers) moves money through a real cash-flow model, scored only on profit. It teaches the cash-flow mechanics people usually learn by losing money: payment retentions, payroll due before income arrives, the cost of idle staff, defects that cost far more at handover, and working capital locked in stock. Its three scenarios are separate economic models, not reskins. Construction: a fixed-price contract, milestone payments that arrive behind the work, retention, crews paid while waiting on materials, and onboarding drag. Startup: no sales before launch, word-of-mouth growth, rising acquisition cost, churn from tech debt, dilutive funding, and an exit priced on growth. Import & Resale: a marketplace fee stack based on published fee structures, duty and exchange-rate exposure, seasonal demand, delayed payouts and ageing stock. Each has its own incidents, leaderboard and end-of-run debrief itemising where the money went. (2) Users: architects, construction and project managers, engineers and small-business owners in the Americas (the app is in English and Mexican Spanish), students of construction management and entrepreneurship, and strategy players who want an economy with real cause and effect. (3) Gap: business games on the App Store are mostly tycoon and idle games where money accrues automatically and nothing models when cash actually arrives, while real project-management simulations are mostly licensed desktop products for classrooms and companies. Critical Path is a short, mobile, bilingual game built on the mechanics that sink real businesses: payment lag, insolvency while profitable on paper, extra people making a late job later, inventory ageing and returns. (4) Testing: the game was tested by playing it throughout development (about 70 iterations since August 2026), and balance was verified with an automated harness that plays many strategies over many random seeds. Changes made from that testing: Hiring was a free speed boost and became a daily wage with onboarding drag. The startup scenario was rebuilt around customers, churn, funding and an exit after play showed it behaved like construction. Runs are now saved the moment they end. (5) It is a standalone product. My account's other apps (such as SharedNapkin, Challenger, PepperTalk, SteadyMind and YourMindSpark) cover sketching, fitness, speaking practice and puzzles; Critical Path is the only simulation or business app. (6) No. None of my other apps deals with business or money, so none could host it, and its three scenarios are already consolidated in one app. (7) No shared code, frameworks or assets. The binary uses only Apple frameworks (SwiftUI, SwiftData, GameKit) and about 11,700 lines of Swift written for this app. All artwork was made for it; only the icon's illustration style resembles my other apps. (8) No third-party SDK, template, engine or content library is used. (9) No. It was not made for a client. I created the original CMSimulator in 2015 and rewrote it from scratch in 2026, and it is published under my own account. Happy to provide anything else that would help.
```

---

## New App Review notes (paste into App Review Information → Notes)

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

## Listing changes worth making before resubmitting

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
