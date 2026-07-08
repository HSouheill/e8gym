#!/bin/zsh
set -e

# Xcode Cloud checks out the repo but never runs Flutter or CocoaPods before
# `xcodebuild archive`. This script installs Flutter and generates the files
# the Xcode project expects (ios/Flutter/Generated.xcconfig, Pods/, and the
# Pods-Runner-*.xcfilelist files) before the build starts.
#
# Docs: https://developer.apple.com/documentation/xcode/build-and-test-flutter-apps

# ci_post_clone.sh runs with CWD set to ios/ci_scripts, so move to the repo root.
cd "$CI_WORKSPACE/repository"

# Install Flutter via git (Xcode Cloud images do not ship with Flutter).
git clone https://github.com/flutter/flutter.git --depth 1 -b stable "$HOME/flutter"
export PATH="$PATH:$HOME/flutter/bin"

# Pre-cache the iOS platform artifacts and fetch Dart dependencies.
flutter precache --ios
flutter pub get

# Xcode Cloud images ship with CocoaPods, but keep this in case that changes.
HOMEBREW_NO_AUTO_UPDATE=1 brew install cocoapods || true

# Generate ios/Pods and the Pods-Runner-*.xcfilelist files xcodebuild needs.
cd ios && pod install

exit 0
