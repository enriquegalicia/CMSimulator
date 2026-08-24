# Game Center setup — what's left to do in App Store Connect

> **Bundle ID changed** (2026-08-23): from `com.magarchitecture.CMSimulator`
> to `com.aguach1leLabs.CMSimulator`, to match the Aguach1leLabs naming
> convention used by your other apps. If leaderboards were ever registered
> in App Store Connect under the old bundle ID, they belong to a different
> app record and won't carry over — this app needs a fresh App Store
> Connect record under the new ID, with the three leaderboards below
> created there from scratch.

The app-side code is done: authentication, three leaderboard submissions
per completed run, and a working "view leaderboard" button. What's *not*
done, and can't be done from code, is registering the leaderboards
themselves — that only exists in App Store Connect, tied to your Apple
Developer account and this app's bundle ID.

## 1. Enable the Game Center capability

Already wired in code (`CMSimulator.entitlements` has
`com.apple.developer.game-center = true`, `GameKit.framework` is linked).
In App Store Connect: **App ▸ [CMSimulator] ▸ Features ▸ Game Center**,
turn it on if it isn't already, for the same bundle ID
(`com.aguach1leLabs.CMSimulator`) this Xcode project uses.

## 2. Create three leaderboards with these exact IDs

The code in `GameCenterManager.swift` submits to these IDs verbatim — a
typo here means scores silently fail to post (visible only in a device
log, not a user-facing error). Same screen: **Features ▸ Game Center ▸
Leaderboards ▸ +**.

| Leaderboard ID | Matches | Sort order |
|---|---|---|
| `com.aguach1leLabs.CMSimulator.costmaster` | Cost Master board | **Low to High** (lower cost wins) |
| `com.aguach1leLabs.CMSimulator.timemaster` | Time Master board | **Low to High** (fewer days wins) |
| `com.aguach1leLabs.CMSimulator.constructionmaster` | Construction Master (combined) board | **Low to High** |

For each: give it a **Reference Name** (internal, e.g. "Cost Master") and
at least one **Leaderboard Localization** (display name + score format —
use "Money" for the cost board with your app's currency, and "Numeric"
or a custom time format for the other two, since the values submitted are
integers: cost in whole currency units, days×10, and a scaled combined
score respectively — see the comments in `GameCenterManager.reportScore`
for exactly how each is computed).

**Sort order defaults to High to Low in the UI — you must change it.** All
three of these are "lower is better," the opposite of a typical points
leaderboard.

## 3. Test it

Leaderboards work in Sandbox / TestFlight once created, even before the
app is live. On a real device (Game Center doesn't authenticate
meaningfully in the simulator without a signed-in sandbox tester):

1. Sign into a **Sandbox Apple Account** (Settings ▸ Game Center on the
   test device, or Xcode will prompt in-app on first launch).
2. Play a run to completion, save a result.
3. Tap the trophy or Game Center icon in-app to open the dashboard and
   confirm the score landed on all three boards.

## 4. If scores don't appear

- Double-check the three IDs above match **exactly** (copy-paste, not
  retyped) — this is the most common failure.
- Confirm Game Center is turned on for this app in App Store Connect, not
  just the entitlement in Xcode.
- Check the device console log for `Game Center score submission failed`
  — `GameCenterManager.reportScore` prints the underlying `GKError` there.
