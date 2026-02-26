#!/usr/bin/env bash
set -euo pipefail

XCODE_APP="/Applications/Xcode.app"
XCODE_DEV_DIR="$XCODE_APP/Contents/Developer"

if [[ ! -d "$XCODE_APP" ]]; then
  echo "Xcode.app not found at $XCODE_APP"
  echo "Install Xcode from the App Store first, then rerun this script."
  exit 1
fi

echo "Selecting active developer directory..."
sudo xcode-select -s "$XCODE_DEV_DIR"

echo "Accepting license / first launch setup..."
sudo xcodebuild -license accept || true
sudo xcodebuild -runFirstLaunch

echo "Installing Rosetta if needed (safe no-op on Intel)..."
/usr/sbin/softwareupdate --install-rosetta --agree-to-license || true

echo "Toolchain status:"
xcode-select -p
xcodebuild -version
swift --version
xcodebuild -showsdks

if command -v xcrun >/dev/null 2>&1; then
  echo "Installed simulators (first 20 lines):"
  xcrun simctl list devices | head -n 20 || true
fi

echo "Done. Xcode toolchain is configured."
