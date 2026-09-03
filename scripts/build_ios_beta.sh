#!/usr/bin/env bash
# Build a signed iOS IPA for TestFlight beta testing.
#
# Prerequisites:
#   1. Apple Developer Program membership ($99/year)
#   2. Xcode signed in: Xcode > Settings > Accounts
#   3. Runner target has a Development Team set in Xcode
#   4. App created in App Store Connect with bundle ID com.rejoicegreatly.app
#   5. .env BASE_URL points to a server testers can reach (not a local IP)
#
# Usage:
#   ./scripts/build_ios_beta.sh
#   ./scripts/build_ios_beta.sh 1.0.0 2          # version 1.0.0, build number 2
#   ./scripts/build_ios_beta.sh --upload           # build then open Transporter

set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

UPLOAD=false
VERSION=""
BUILD_NUMBER=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --upload)
      UPLOAD=true
      shift
      ;;
    *)
      if [[ -z "$VERSION" ]]; then
        VERSION="$1"
      elif [[ -z "$BUILD_NUMBER" ]]; then
        BUILD_NUMBER="$1"
      else
        echo "Unknown argument: $1" >&2
        exit 1
      fi
      shift
      ;;
  esac
done

if [[ -f .env ]]; then
  BASE_URL="$(grep -E '^BASE_URL=' .env | cut -d= -f2- || true)"
  if [[ "$BASE_URL" =~ ^https?://(192\.168\.|10\.|172\.(1[6-9]|2[0-9]|3[01])\.|127\.|localhost) ]]; then
    echo "Warning: BASE_URL in .env looks like a local/private address:"
    echo "  $BASE_URL"
    echo "Testers on other networks will not reach your backend. Use a public URL before beta."
    echo ""
  fi
fi

BUILD_ARGS=(build ipa --release)
if [[ -n "$VERSION" ]]; then
  BUILD_ARGS+=(--build-name="$VERSION")
fi
if [[ -n "$BUILD_NUMBER" ]]; then
  BUILD_ARGS+=(--build-number="$BUILD_NUMBER")
fi

echo "==> flutter pub get"
flutter pub get

echo "==> flutter ${BUILD_ARGS[*]}"
flutter "${BUILD_ARGS[@]}"

IPA="$(find build/ios/ipa -name '*.ipa' -print -quit 2>/dev/null || true)"
if [[ -z "$IPA" ]]; then
  echo "Build finished but no IPA was found under build/ios/ipa/" >&2
  exit 1
fi

echo ""
echo "Success. IPA ready for TestFlight:"
echo "  $IPA"
echo ""
echo "Next steps:"
echo "  1. Open App Store Connect: https://appstoreconnect.apple.com"
echo "  2. Upload the IPA with Transporter (Mac App Store) or Xcode Organizer"
echo "  3. In TestFlight, add testers by email (Internal or External group)"
echo ""
echo "Upload from Terminal (optional):"
echo "  xcrun altool --upload-app -f \"$IPA\" -t ios -u YOUR_APPLE_ID -p YOUR_APP_SPECIFIC_PASSWORD"

if [[ "$UPLOAD" == true ]]; then
  if open -a Transporter "$IPA" 2>/dev/null; then
    echo "Opened Transporter with the IPA."
  else
    echo "Transporter not installed. Install it from the Mac App Store, then drag the IPA in."
  fi
fi
