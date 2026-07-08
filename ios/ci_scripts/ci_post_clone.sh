#!/bin/zsh
set -e

# Xcode Cloud checks out the repo but never runs Flutter or CocoaPods before
# `xcodebuild archive`. This script installs Flutter and generates the files
# the Xcode project expects (ios/Flutter/Generated.xcconfig, Pods/, and the
# Pods-Runner-*.xcfilelist files) before the build starts.
#
# Docs: https://developer.apple.com/documentation/xcode/build-and-test-flutter-apps

# ci_post_clone.sh runs with CWD set to ios/ci_scripts. $CI_WORKSPACE isn't
# reliably set, so resolve the repo root relative to this script instead.
cd "$(dirname "$0")/../.."

# Install Flutter via git (Xcode Cloud images do not ship with Flutter).
git clone https://github.com/flutter/flutter.git --depth 1 -b stable "$HOME/flutter"
export PATH="$PATH:$HOME/flutter/bin"

flutter clean
flutter precache --ios
flutter pub get

# Xcode Cloud images ship with CocoaPods, but keep this in case that changes.
HOMEBREW_NO_AUTO_UPDATE=1 brew install cocoapods || true

# Generate ios/Pods and the Pods-Runner-*.xcfilelist files xcodebuild needs.
(cd ios && pod install)

# Sanity check: Runner.xcodeproj is CocoaPods-only (no Swift Package Manager
# integration). podhelper.rb reads .flutter-plugins-dependencies and skips a
# plugin from CocoaPods if Swift Package Manager is enabled and that plugin
# ships a Package.swift (see pubspec.yaml's flutter.config for why that's
# disabled here). If it ever gets skipped anyway, it's installed nowhere and
# xcodebuild fails much later with a confusing "Module 'X' not found" instead
# of a clear dependency-resolution error here, so verify every native iOS
# plugin that pub get resolved actually made it into Podfile.lock.
python3 - <<'PY'
import json
import re
import sys

with open(".flutter-plugins-dependencies") as f:
    data = json.load(f)

expected = {
    plugin["name"]
    for plugin in data.get("plugins", {}).get("ios", [])
    if plugin.get("native_build", True) and plugin.get("path")
}

with open("ios/Podfile.lock") as f:
    lock = f.read()

installed = set(re.findall(r"^  - ([A-Za-z0-9_]+) \(", lock, re.MULTILINE))

missing = sorted(expected - installed)
if missing:
    print(
        "error: pod install did not add expected iOS plugin pod(s): "
        + ", ".join(missing),
        file=sys.stderr,
    )
    sys.exit(1)
PY

exit 0
