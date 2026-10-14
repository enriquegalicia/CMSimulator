#!/bin/zsh
# Captures the App Store screenshots for Critical Path, in English and Spanish,
# on the three sizes App Store Connect wants:
#   iphone-6.3  iPhone 17 Pro           1206 × 2622  (required)
#   iphone-6.9  iPhone 17 Pro Max       1320 × 2868
#   ipad-13     iPad Pro 13-inch (M5)   2064 × 2752  (required: the app runs on iPad)
#
#   Scripts/capture_screenshots.sh                  # everything
#   Scripts/capture_screenshots.sh iphone-6.3       # one size
#   SHOTS="board debrief" Scripts/capture_screenshots.sh iphone-6.3
#
# The build sets STORE_SCREENSHOTS, which lets `-StoreShot <id>` stage a real
# run (see Sources/Engine/StoreScreenshots.swift). It also signs without the
# Game Center entitlement, because iOS shows its own Game Center sign-in sheet
# over any Game Center app on a fresh simulator, and that sheet can't be
# dismissed from a script. Nothing else differs from the shipping build.
#
# Uses dedicated "CP …" simulators (created on first run), so other projects'
# simulators are never touched. Output: documentation/store-assets/<slot>/<lang>-NN-<id>.png
set -euo pipefail
export DEVELOPER_DIR=${DEVELOPER_DIR:-/Applications/Xcode.app/Contents/Developer}

ROOT=${0:A:h:h}
OUT=$ROOT/documentation/store-assets
DERIVED=${TMPDIR:-/tmp}/criticalpath-screenshots
BUNDLE=com.aguach1leLabs.CriticalPath
RUNTIME=com.apple.CoreSimulator.SimRuntime.iOS-26-5

# Story order: the number in the file name is the App Store order.
ORDER=(board debrief picker trading growth levers hiring suppliers risk log)
SHOTS=(${=SHOTS:-$ORDER})
LANGS=(en es)
typeset -A LOCALE=(en en_US es es_MX)
typeset -A DEVICE=(iphone-6.3 "iPhone 17 Pro" iphone-6.9 "iPhone 17 Pro Max" ipad-13 "iPad Pro 13-inch (M5)")
SLOTS=(${@:-iphone-6.3 iphone-6.9 ipad-13})

echo "Building with STORE_SCREENSHOTS…"
xcodebuild -project $ROOT/CMSimulator.xcodeproj -scheme CriticalPathSim \
  -destination 'generic/platform=iOS Simulator' -derivedDataPath $DERIVED \
  SWIFT_ACTIVE_COMPILATION_CONDITIONS=STORE_SCREENSHOTS CODE_SIGN_ENTITLEMENTS= \
  build -quiet
APP=$DERIVED/Build/Products/Debug-iphonesimulator/CriticalPathSim.app

device_id() {  # dedicated simulator per size, created once
  local name="CP $1"
  local id=$(xcrun simctl list devices | grep -F "$name (" | head -1 | sed -E 's/.*\(([0-9A-F-]{36})\).*/\1/')
  [[ -n $id ]] || id=$(xcrun simctl create "$name" "$1" $RUNTIME)
  echo $id
}

# Waits for the staged screen: past the launch screen, and unchanged for two polls.
capture() {
  local dev=$1 file=$2 prev="" cur="" n=0
  local first=$(mktemp).png
  sleep 2; xcrun simctl io $dev screenshot $first >/dev/null 2>&1
  local floor=$(( $(stat -f%z $first) * 3 / 2 ))
  while (( n < 60 )); do
    sleep 3; xcrun simctl io $dev screenshot $file >/dev/null 2>&1
    cur=$(md5 -q $file)
    if (( $(stat -f%z $file) > floor )) && [[ $cur == $prev ]]; then return 0; fi
    prev=$cur; (( n++ ))
  done
  echo "  timed out waiting for a stable frame: $file" >&2
}

for slot in $SLOTS; do
  dev=$(device_id "${DEVICE[$slot]}")
  echo "$slot → ${DEVICE[$slot]} ($dev)"
  xcrun simctl boot $dev 2>/dev/null || true
  xcrun simctl bootstatus $dev -b >/dev/null
  xcrun simctl ui $dev appearance dark
  xcrun simctl status_bar $dev override --time 9:41 --batteryState charged --batteryLevel 100 \
    --cellularMode active --cellularBars 4 --wifiBars 3
  xcrun simctl uninstall $dev $BUNDLE 2>/dev/null || true
  xcrun simctl install $dev $APP
  mkdir -p $OUT/$slot
  for lang in $LANGS; do
    for shot in $SHOTS; do
      num=$(printf %02d ${ORDER[(i)$shot]})
      file=$OUT/$slot/$lang-$num-$shot.png
      xcrun simctl terminate $dev $BUNDLE 2>/dev/null || true
      xcrun simctl launch $dev $BUNDLE -StoreShot $shot \
        -AppleLanguages "($lang)" -AppleLocale ${LOCALE[$lang]} >/dev/null
      capture $dev $file
      echo "  $lang-$num-$shot"
    done
  done
  xcrun simctl terminate $dev $BUNDLE 2>/dev/null || true
done
echo "Done. Check: python3 ~/Desktop/Xcode/Aguach1leLabs/scripts/store_assets.py check $ROOT"
