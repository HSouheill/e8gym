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

# Federated plugins whose iOS implementation pod has, on past runs, been
# silently dropped from .flutter-plugins-dependencies by a cold-cache
# `flutter pub get` in a fresh CI container. When that happens the Podfile
# skips the pod entirely and xcodebuild fails much later with a confusing
# "Module 'X' not found" instead of a clear dependency-resolution error here.
# Running pub get/pod install twice was tried before as a workaround but is
# not reliable, so this script verifies the result and retries a clean
# resolution if any expected pod is still missing.
expected_ios_pods=(image_picker_ios url_launcher_ios path_provider_foundation shared_preferences_foundation)

resolve_and_install() {
  flutter clean
  flutter precache --ios
  flutter pub get

  # Xcode Cloud images ship with CocoaPods, but keep this in case that changes.
  HOMEBREW_NO_AUTO_UPDATE=1 brew install cocoapods || true

  # Generate ios/Pods and the Pods-Runner-*.xcfilelist files xcodebuild needs.
  (cd ios && pod install)
}

resolve_and_install

attempt=1
max_attempts=3
while true; do
  missing=()
  for pod_name in "${expected_ios_pods[@]}"; do
    if [ ! -d "ios/Pods/${pod_name}" ]; then
      missing+=("$pod_name")
    fi
  done

  if [ ${#missing[@]} -eq 0 ]; then
    break
  fi

  echo "warning: pod install produced an incomplete Pods/ directory, missing: ${missing[*]} (attempt $attempt/$max_attempts)"
  if [ "$attempt" -ge "$max_attempts" ]; then
    echo "error: ios/Pods is still missing pods after $max_attempts attempts: ${missing[*]}"
    exit 1
  fi

  # Force a fully clean plugin/pod re-resolution rather than trusting the
  # stale generated files, then retry.
  rm -rf .dart_tool .flutter-plugins .flutter-plugins-dependencies ios/Podfile.lock ios/Pods ios/.symlinks
  attempt=$((attempt + 1))
  resolve_and_install
done

exit 0
