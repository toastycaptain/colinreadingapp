# Local Apple/Xcode Toolchain Setup

## Current machine state
- Xcode app is not installed.
- Active developer dir is currently Command Line Tools only:
  - `/Library/Developer/CommandLineTools`
- `xcodebuild` is unavailable until full Xcode is installed.

## Install Xcode
Option 1 (recommended):
1. Open App Store.
2. Install **Xcode** (Apple).
3. Launch Xcode once and let it finish component installation.

Option 2 (CLI, requires admin password and App Store sign-in):
```bash
mas get 497799835
```

## Bootstrap toolchain (after Xcode install)
From repo root:
```bash
./ios/scripts/bootstrap_xcode_toolchain.sh
```

This script will:
- set `xcode-select` to `/Applications/Xcode.app/Contents/Developer`
- accept license and run first launch setup
- print SDK/tool versions and simulator availability

## Verify
```bash
xcode-select -p
xcodebuild -version
xcodebuild -showsdks
xcrun simctl list devices
```

## Note for this repo
`ios/StorytimeApp` currently contains Swift sources only.
You still need an Xcode project/target to build and run in Simulator.
Use `ios/LAUNCH_READINESS_CHECKLIST.md` for the expected project wiring.
