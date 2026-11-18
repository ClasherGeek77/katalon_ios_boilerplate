# katalon_ios_boilerplate

A Katalon Studio mobile test project for iOS: 7 tests of a small Flutter app (counter page, login screen, login errors, login and logout) driven through Appium and XCUITest on the iOS Simulator, with xpath locators stored in the Object Repository. The app under test is downloaded from a GitHub release, so you never build it.

This project is macOS only (it needs Xcode and the iOS Simulator). It has no predecessor repo, so there is no `legacy` branch.

## when to use it

Use it to learn or start a Katalon iOS project: mobile Object Repository, `Mobile.*` keywords, one custom keyword for typing into Flutter fields.

Do not use it if:

- you want mobile tests as Python code with pytest and Appium: use https://github.com/ClasherGeek77/pytest_ios_boilerplate
- you want Android: use https://github.com/ClasherGeek77/katalon_android_boilerplate
- you are not on a Mac, or want the simplest Katalon project (no simulator): use https://github.com/ClasherGeek77/katalon_web_boilerplate or https://github.com/ClasherGeek77/katalon_api_boilerplate

This is one of the heaviest boilerplates: Xcode, a simulator and an Appium setup next to Katalon.

## what you need

| need | detail |
|---|---|
| macOS with Xcode | the runs recorded for this project used Xcode 12.4 and the iOS 14.4 simulator runtime. Newer Xcode versions: not verified. Get Xcode from the Mac App Store or https://developer.apple.com/download/. |
| an Intel Mac | the released app is an x86_64 simulator build. Apple Silicon: not verified. |
| a simulator named `iPhoneSE14` | iOS 14.4. `run_katalon.sh` boots it by that name and passes `platformVersion=14.4`. Create it, for example: `xcrun simctl create iPhoneSE14 "iPhone SE (2nd generation)" com.apple.CoreSimulator.SimRuntime.iOS-14-4` (not run here; `xcrun simctl list devicetypes runtimes` shows the exact ids on your machine). |
| Katalon Studio 7.9.1 | the version recorded in `.classpath`; the project was created with it. Download from https://katalon.com/download (older versions are listed on Katalon's release pages). On macOS 10.15, 7.9.1 is the build to use. On a newer OS a current Studio should open and upgrade the project (not verified). |
| Katalon account / licence | Studio asks you to sign in. Running from the command line needs Katalon Runtime Engine, a licensed product; check the current terms on https://katalon.com. Not verified here. |
| Node.js | needed by the Appium shim below (command-line path only) |
| git, curl, unzip | `fetch_app.sh` uses `curl`, `unzip` and `shasum` |

The command-line path also needs the "environment for mobile runs" below.

## quick start

Get the project and the app:

```bash
git clone https://github.com/ClasherGeek77/katalon_ios_boilerplate.git
cd katalon_ios_boilerplate
./fetch_app.sh
```

`fetch_app.sh` downloads `ted_mobile_app_test-v1.0.0-ios-simulator.zip` from https://github.com/ClasherGeek77/mobile_app_mock/releases/tag/v1.0.0 into `apps/` (git-ignored), checks it against the release `SHA256SUMS.txt` and unzips `Runner.app` (bundle id `net.ted.flutterApp`). You should see:

```
ok  ted_mobile_app_test-v1.0.0-ios-simulator.zip
app ready in apps/
```

`APP_VERSION=v1.0.0 ./fetch_app.sh` picks a release tag. A checksum mismatch deletes the file and exits 1; run it again.

### run in Katalon Studio (no shims of your own)

1. Open Katalon Studio and sign in.
2. File > Open Project, pick the cloned folder (it contains `katalon_boilerplate_ios.prj`).
3. Boot the `iPhoneSE14` simulator and install the app: `xcrun simctl boot iPhoneSE14` then `xcrun simctl install booted apps/Runner.app`.
4. Open `Test Suites/ios/ios_smoke`, choose the iOS simulator in the run dropdown and run it.

Studio is the intended GUI path and does not use the shim environment below; whether Studio 7.9.1 then runs with its own bundled Appium on your machine is not verified here. One catch: the tracked file `settings/internal/com.kms.katalon.core.mobile.ios.properties` holds a `deviceId` (the simulator UDID of the author's machine) and `appiumPath` / `appiumDirectory` pointing at the shim folder. On your machine fix the UDID (`xcrun simctl list devices`) and remove or correct the two Appium keys (or reset them in Studio's project settings for iOS) before the first run. Not verified in Studio here.

You should see 7 test cases run in the simulator and pass. The first run builds WebDriverAgent, which takes a while.

### run from the command line

```bash
./run_katalon.sh                                  # Test Suites/ios/ios_smoke
./run_katalon.sh "Test Suites/ios/only_ios004"    # one test only
KATALON_BIN=/path/to/your/launcher ./run_katalon.sh
```

What the script does, in order:

1. sets `DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer` (edit it if Xcode is elsewhere) and `APPIUM_HOME=$HOME/.katalon_appium_shim`
2. boots the simulator `iPhoneSE14` if it is not booted, installs `apps/Runner.app` if the app is absent (running `./fetch_app.sh` first when `apps/Runner.app` is missing)
3. macOS shows a firewall prompt ("WebDriverAgentRunner-Runner.app wants to accept incoming connections") for every freshly installed WebDriverAgent runner. The script tries to register each new runner with `socketfilterfw` using `sudo -n`, which only works when your user has passwordless sudo. Otherwise it does nothing and you click Allow on the prompt when it appears.
4. kills a running Android emulator through `~/Library/Android/sdk/platform-tools/adb` (a no-op when that does not exist), kills a running `appium --port 4723` and any leftover `katalon_appium` process
5. calls `$KATALON_BIN <project dir> -testSuitePath=<suite> -browserType=iOS -executionProfile=default -retry=0 -data ~/.katalon_console/ws-ios --executionProperties "devicePlatform=IOS deviceId=<booted simulator udid> platformVersion=14.4"`

`KATALON_BIN` defaults to `~/.local/bin/katalon`; that launcher is not part of this repo. It must accept the project directory first, then the options above, and start Katalon in console mode. With only the stock `katalonc` you need a wrapper that adds `-runMode=console`, `-projectPath=<dir>` and your `-apiKey`. Not verified with the stock binary. Optional `KATALON_WATCH`: an executable that takes the log path, started in the background.

The log goes to `~/katalon_cli_runs/ios-<timestamp>.log`. You should see `GREEN: katalonc exited 0, report in Reports/` and a `JUnit_Report.xml` with `tests="7" failures="0"` (`tests="1"` for a single-test suite).

## environment for mobile runs (command-line path only)

Katalon Runtime 7.9.1 drives Appium 1 style servers, and the script points it at two folders in your home directory. They are not part of this repo and not created by any script here:

| folder | what it is |
|---|---|
| `~/.katalon_appium1` | an npm install of `appium` 1.22.3. On the machine these runs were recorded on, its nested XCUITest driver was 3.59.0, which builds WebDriverAgent on Xcode 12.4 (a newer 7.x driver does not, per the earlier notes of this project; not re-checked). |
| `~/.katalon_appium_shim` | `node_modules/appium/build/lib/main.js`, a small wrapper Katalon launches instead of Appium. Katalon 7.9.1 starts Appium with `--webkit-debug-proxy-port 0`, which Appium 1.22 rejects; the wrapper drops that flag, starts the real Appium from `~/.katalon_appium1`, forwards termination signals and kills the child on exit so a killed run cannot leave a stale server. |

The wrapper's logic is a few lines (your own version, with your own paths, must do the same; this form was not run as written):

```js
// ~/.katalon_appium_shim/node_modules/appium/build/lib/main.js
const cp = require("child_process");
const os = require("os");
const a = process.argv.slice(2);
const i = a.indexOf("--webkit-debug-proxy-port");
if (i > -1 && a[i + 1] === "0") a.splice(i, 2);
const real = os.homedir() + "/.katalon_appium1/node_modules/appium/build/lib/main.js";
const c = cp.spawn(process.execPath, [real, ...a], { stdio: "inherit" });
c.on("exit", code => process.exit(code || 0));
["SIGINT", "SIGTERM", "SIGHUP"].forEach(s => process.on(s, () => { try { c.kill("SIGTERM"); } catch (e) {} }));
process.on("exit", () => { try { c.kill("SIGKILL"); } catch (e) {} });
```

## the 7 tests

| test case | what it checks |
|---|---|
| `ios-001-app-opens-on-the-counter-page` | Login button and the counter label are visible |
| `ios-002-login-screen-opens` | tapping Login shows the Sign In button |
| `ios-003-empty-username-is-refused` | error `Epic sadface: Username is required` |
| `ios-004-empty-password-is-refused` | error `Epic sadface: Password is required` |
| `ios-005-wrong-password-is-refused` | error `Epic sadface: Username and password do not match any user in this service` |
| `ios-006-locked-out-is-refused` | `locked_out_user` gets `Epic sadface: Sorry, this user has been locked out.` |
| `ios-007-login-success-then-logout` | `standard_user` / `secret_sauce` logs in, name shown, Logout returns to the Login button |

Naming: test cases are `ios-<number>-<what happens, in words>`; the suite is `ios_smoke`; `only_ios001`, `only_ios004` and `only_ios007` are one-test suites for debugging a single case (copy one for another test).

## how to read the code

```
Object Repository/{home,login}/*.rs                      11 mobile objects, xpath locators
Test Cases/ios/*.tc                                      the test case entries
Scripts/ios/<test case>/Script<timestamp>.groovy         the steps of each test case
Test Suites/ios/ios_smoke.ts, only_ios00X.ts             the full suite and one-test suites
Keywords/ios/common/FlutterInput.groovy                  the one custom keyword (typing)
Profiles/default.glbl                                    APP_PATH = <project>/apps/Runner.app
settings/internal/...mobile.ios.properties               simulator id, Appium location
run_katalon.sh, fetch_app.sh                             runner, app downloader
```

Locators are xpath, stored in the Object Repository, not in scripts. Open `Object Repository/login/input_username.rs`: the locator is `//XCUIElementTypeTextField[@name='Username']`, strategy XPATH. Buttons and texts use the accessibility name, e.g. `//XCUIElementTypeButton[@name='Login']` or `//*[@name='standard_user']`. The four error sentences are four separate objects instead of one xpath built in code. A script names the object, never the xpath:

```groovy
Mobile.startApplication(GlobalVariable.APP_PATH.toString(), true)
Mobile.tap(findTestObject('Object Repository/home/button_login'), 20)
FlutterInput.type(findTestObject('Object Repository/login/input_username'), 'standard_user')
Mobile.verifyElementVisible(findTestObject('Object Repository/home/txt_user_standard_user'), 30)
```

Typing is the one custom call. With this Appium/XCUITest combination, sending keys to a Flutter field hangs, so `FlutterInput.type` finds the field from the Object Repository xpath, long-presses it (`mobile: touchAndHold`) to open the edit menu, puts the value on the clipboard, taps Paste and waits for the menu to close.

Debugging a failure: run one test case at a time with a one-test suite (`./run_katalon.sh "Test Suites/ios/only_ios004"`), the full suite last.

Not included on purpose: real devices, device farms, Cucumber, data-driven CSV, TestOps.

## if it breaks

| symptom | cause | fix |
|---|---|---|
| `fetch_app.sh`: `checksum mismatch` | broken download | run it again |
| simulator not found / `iPhoneSE14` missing | the simulator name is not created | create it (command above) |
| macOS asks to allow `WebDriverAgentRunner-Runner.app` incoming connections | firewall prompt for a new WebDriverAgent install | click Allow (the script only avoids it with passwordless sudo) |
| Appium fails at start with `--webkit-debug-proxy-port` error | Katalon launched plain Appium 1.22 without the wrapper | use the wrapper described above |
| WebDriverAgent build fails | Xcode or driver version mismatch | the recorded runs used Xcode 12.4 with XCUITest driver 3.59.0; other combinations are not verified |
| typing into a field hangs | `send_keys` on Flutter fields | use `FlutterInput.type` (the scripts already do) |
| a leftover Appium server blocks the next run | a killed run | `pkill -f katalon_appium`, rerun |
| `./run_katalon.sh`: no such file or directory | no launcher at `~/.local/bin/katalon` | set `KATALON_BIN`, or run in Studio |
| blocking native dialog in console runs | stale workspace index in `~/.katalon_console/ws-ios` | delete that folder and rerun |

## next

- the same journeys in pytest and Appium 2: https://github.com/ClasherGeek77/pytest_ios_boilerplate
- Android in Katalon: https://github.com/ClasherGeek77/katalon_android_boilerplate
- the app under test and its releases: https://github.com/ClasherGeek77/mobile_app_mock
