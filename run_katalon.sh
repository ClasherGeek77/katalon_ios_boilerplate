#!/bin/bash
# runs the mobile suite through the offline Katalon KRE, which drives the
# LOCAL appium 2.11.5 (xcuitest@5.6.0) against the iPhoneSE14 simulator.
# device + appium are prepared here first, one JVM at a time
cd "$(dirname "$0")"

SUITE="${1:-Test Suites/ios/ios_smoke}"
mkdir -p ~/katalon_cli_runs
TS=$(date +%Y-%m-%d_%H-%M-%S)
LOG="$HOME/katalon_cli_runs/ios-$TS.log"

export DEVELOPER_DIR="/Applications/Xcode.app/Contents/Developer"
export PATH="$HOME/.local/bin:/usr/local/bin:$PATH"
# KRE resolves its appium dir through APPIUM_HOME + the ios settings file:
# appium 1.22.3 tree (~/.katalon_appium1, xcuitest driver 3.59.0) behind the
# shim (~/.katalon_appium_shim) that strips KRE's bogus
# --webkit-debug-proxy-port 0. appium1 listens on a KRE-chosen random port, so
# no clash with the appium 2 stack on 4723.
export APPIUM_HOME="$HOME/.katalon_appium_shim"

# the simulator: boot iPhoneSE14 when dark, install the app when absent
if ! xcrun simctl list devices booted | grep -q iPhoneSE14; then
    echo "booting iPhoneSE14"
    xcrun simctl boot iPhoneSE14 || { echo "no simulator named iPhoneSE14, create one: xcrun simctl create iPhoneSE14 com.apple.CoreSimulator.SimDeviceType.iPhone-SE--2nd-generation- com.apple.CoreSimulator.SimRuntime.iOS-14-4"; exit 1; }
    sleep 8
fi
[ -d apps/Runner.app ] || ./fetch_app.sh
if ! xcrun simctl get_app_container booted net.ted.flutterApp >/dev/null 2>&1; then
    xcrun simctl install booted \
        "$(pwd)/apps/Runner.app"
fi

# firewall: the macOS prompt follows the WDA container copy's PATH (every
# sim install is a new path), so pre-permit known builds AND run a 1 s guard
# while KRE is up that registers freshly installed runners — Ted never sees
# "WebDriverAgentRunner-Runner.app wants to accept incoming connections"
for WDAR in "$HOME"/Library/Developer/Xcode/DerivedData/WebDriverAgent-*/Build/Products/Debug-iphonesimulator/WebDriverAgentRunner-Runner.app/WebDriverAgentRunner-Runner; do
    [ -f "$WDAR" ] || continue
    sudo -n /usr/libexec/ApplicationFirewall/socketfilterfw --add "$WDAR" >/dev/null 2>&1
    sudo -n /usr/libexec/ApplicationFirewall/socketfilterfw --unblockapp "$WDAR" >/dev/null 2>&1
done
( mkdir -p /tmp/wda_seen.d
  while pgrep -q katalonc; do
      for W in "$HOME"/Library/Developer/CoreSimulator/Devices/*/data/Containers/Bundle/Application/*/WebDriverAgentRunner-Runner.app/WebDriverAgentRunner-Runner; do
          [ -f "$W" ] || continue
          K=$(printf '%s' "$W" | md5)
          [ -f "/tmp/wda_seen.d/$K" ] && continue
          sudo -n /usr/libexec/ApplicationFirewall/socketfilterfw --add "$W" >/dev/null 2>&1
          sudo -n /usr/libexec/ApplicationFirewall/socketfilterfw --unblockapp "$W" >/dev/null 2>&1
          : > "/tmp/wda_seen.d/$K"
      done
      sleep 0.3
  done ) & GPID=$!

# stop the android emulator first: two virtual devices at once is too heavy for most laptops
"${ANDROID_HOME:-$HOME/Library/Android/sdk}/platform-tools/adb" emu kill 2>/dev/null || true

# KRE starts its OWN appium: free the port from the pytest-side server first
pkill -f "appium --port 4723" 2>/dev/null || true
# clear appium-1 servers orphaned by a killed parent (a stale session wedges
# the next run's install/launch)
pkill -f "katalon_appium" 2>/dev/null || true

SIM_UDID=$(xcrun simctl list devices booted -j | python3 -c "import json,sys; [print(v[0]['udid']) for k,v in json.load(sys.stdin)['devices'].items() if any(d['state']=='Booted' for d in v)]" | head -1)
# the settings file KRE reads is machine specific (simulator id, appium dir), so it
# is written here and git-ignored
mkdir -p settings/internal
cat > settings/internal/com.kms.katalon.core.mobile.ios.properties <<JSON
{
 "IOS_DRIVER": {
  "deviceId": "$SIM_UDID",
  "appiumPath": "$APPIUM_HOME",
  "executionMode": "Local installation",
  "appiumDirectory": "$APPIUM_HOME"
 }
}
JSON
echo "running $SUITE on $SIM_UDID -> $LOG"
# optional live progress watcher, point KATALON_WATCH at any script that takes the log path
WPID=""
if [ -x "${KATALON_WATCH:-}" ]; then "$KATALON_WATCH" "$LOG" & WPID=$!; fi
"${KATALON_BIN:-$HOME/.local/bin/katalon}" "$(pwd)" \
    -testSuitePath="$SUITE" \
    -browserType=iOS \
    -executionProfile=default \
    -retry=0 -data ~/.katalon_console/ws-ios \
    --executionProperties "devicePlatform=IOS deviceId=$SIM_UDID platformVersion=14.4" > "$LOG" 2>&1
RC=$?
[ -n "$WPID" ] && kill $WPID 2>/dev/null

grep -E "Test Suites:|Test Cases:|FAILED|ERROR" "$LOG" | tail -8
if [ $RC -eq 0 ]; then
    echo "GREEN: katalonc exited 0, report in Reports/"
else
    echo "RED: katalonc exit $RC, full log: $LOG"
fi
exit $RC
