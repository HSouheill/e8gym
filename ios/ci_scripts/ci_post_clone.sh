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

# Force a clean regeneration of plugin registration files. A plain `pub get`
# has been observed to write an incomplete .flutter-plugins-dependencies on
# first run in CI (missing some federated iOS plugins such as image_picker_ios),
# which then makes the Podfile skip those pods and the build fails later with
# "Module 'X' not found". `flutter clean` removes the generated files so the
# next `pub get` rebuilds the plugin list from scratch.
flutter clean

# Pre-cache the iOS platform artifacts and fetch Dart dependencies.
flutter precache --ios
flutter pub get

# .flutter-plugins-dependencies (which the Podfile reads to decide which iOS
# pods to install) has been observed to come out incomplete after the very
# first `pub get` in a fresh CI environment, silently dropping federated
# plugins like image_picker_ios and failing the build much later at compile
# time with a confusing "Module 'X' not found" error. Re-running pub get is
# idempotent and cheap, and reliably regenerates the file in full.
flutter pub get

# Xcode Cloud images ship with CocoaPods, but keep this in case that changes.
HOMEBREW_NO_AUTO_UPDATE=1 brew install cocoapods || true

# Generate ios/Pods and the Pods-Runner-*.xcfilelist files xcodebuild needs.
cd ios && pod install

exit 0
