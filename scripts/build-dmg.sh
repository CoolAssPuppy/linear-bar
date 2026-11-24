#!/bin/bash
#
# Build a distributable, notarized, Sparkle-signed DMG for Linear Bar.
#
# Prerequisites:
#   1. Xcode Archive + Developer ID export of "Linear Bar.app" (the .app
#      must already be signed with Developer ID and notarized+stapled).
#   2. `uv tool install dmgbuild==1.6.7`
#   3. Background TIFF at dmg-assets/background.tiff (see dmg-assets/README.md).
#   4. A `notarytool` keychain profile stored via:
#        xcrun notarytool store-credentials <profile-name> --apple-id ... --team-id ... --password ...
#   5. Sparkle `sign_update` tool at ~/bin/sparkle/sign_update (see SPARKLE.md).
#
# Usage:
#   ./scripts/build-dmg.sh <path-to-Linear-Bar.app> <version> <notarytool-profile>
#
# Output:
#   dist/LinearBar-<version>.dmg               (signed, notarized, stapled)
#   dist/LinearBar-<version>.sparkle.txt       (edSignature + length for appcast)

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SCRIPTS="$REPO_ROOT/scripts"
APP_PATH="${1:?Usage: $0 <path-to-Linear-Bar.app> <version> <notarytool-profile>}"
VERSION="${2:?Usage: $0 <path-to-Linear-Bar.app> <version> <notarytool-profile>}"
NOTARY_PROFILE="${3:?Usage: $0 <path-to-Linear-Bar.app> <version> <notarytool-profile>}"

SIGN_UPDATE="${SPARKLE_SIGN_UPDATE:-$HOME/bin/sparkle/sign_update}"
# Linear Bar and Mail Notifier share one Sparkle EdDSA key pair, and the
# keychain item holding it is named for Mail Notifier. Linear Bar's
# SUPublicEDKey (pySvjKDODAzK9Eiao1Cxni5AW6+rlLGUFOWAnaoAlfw=) is that pair's
# public half, so this is the only key that produces updates existing installs
# will accept. There is no keychain item under com.strategicnerds.LinearBarApp;
# the old default here silently pointed at nothing.
SPARKLE_KEY_ACCOUNT="${SPARKLE_KEY_ACCOUNT:-com.strategicnerds.MailNotifierApp}"

BACKGROUND="$REPO_ROOT/dmg-assets/background.tiff"
VOLUME_ICON="$REPO_ROOT/dmg-assets/VolumeIcon.icns"
DMG_OUT="$REPO_ROOT/dist/LinearBar-$VERSION.dmg"

if [[ ! -d "$APP_PATH" ]]; then
  echo "Error: App not found at $APP_PATH"
  exit 1
fi

if [[ ! -f "$BACKGROUND" ]]; then
  echo "Error: Background TIFF not found at $BACKGROUND"
  echo "See dmg-assets/README.md for how to generate one from a 1320x800 PNG."
  exit 1
fi

if ! command -v dmgbuild >/dev/null 2>&1; then
  echo "Error: dmgbuild not installed. Run: uv tool install dmgbuild==1.6.7"
  exit 1
fi

if [[ ! -x "$SIGN_UPDATE" ]]; then
  echo "Error: Sparkle sign_update not found at $SIGN_UPDATE"
  echo "Install it (see SPARKLE.md) or set SPARKLE_SIGN_UPDATE to its path."
  exit 1
fi

mkdir -p "$REPO_ROOT/dist"
rm -f "$DMG_OUT"

echo "Building DMG for Linear Bar v$VERSION..."
echo "  App:        $APP_PATH"
echo "  Background: $BACKGROUND"
echo "  Output:     $DMG_OUT"
echo ""

# dmgbuild writes the Finder layout directly into .DS_Store. This keeps the
# standard background and icon positions without Apple Events permission.
dmgbuild \
  -s "$SCRIPTS/dmg-settings.py" \
  -D app="$APP_PATH" \
  -D background="$BACKGROUND" \
  -D volume_icon="$VOLUME_ICON" \
  "Linear Bar" \
  "$DMG_OUT"

VERIFY_MOUNT=$(mktemp -d)
cleanup_mount() {
  hdiutil detach "$VERIFY_MOUNT" -quiet 2>/dev/null || true
  rmdir "$VERIFY_MOUNT" 2>/dev/null || true
}
trap cleanup_mount EXIT

echo "Verifying DMG contents and Finder layout..."
hdiutil attach "$DMG_OUT" -readonly -nobrowse -mountpoint "$VERIFY_MOUNT" -quiet
[[ -d "$VERIFY_MOUNT/Linear Bar.app" ]]
[[ -L "$VERIFY_MOUNT/Applications" ]]
[[ -f "$VERIFY_MOUNT/.DS_Store" ]]
BACKGROUND_NAME=".$(basename "$BACKGROUND")"
[[ -f "$VERIFY_MOUNT/$BACKGROUND_NAME" ]]
cmp -s "$BACKGROUND" "$VERIFY_MOUNT/$BACKGROUND_NAME"
strings "$VERIFY_MOUNT/.DS_Store" | grep -Fq "$BACKGROUND_NAME"
cleanup_mount
trap - EXIT

echo ""
echo "DMG built: $DMG_OUT"
echo ""

SIGN_IDENTITY="${SIGN_IDENTITY:-Developer ID Application: Prashant Sridharan (955GSY56UT)}"
echo "Codesigning DMG with: $SIGN_IDENTITY"
codesign --force --sign "$SIGN_IDENTITY" --timestamp "$DMG_OUT"

echo "Notarizing DMG (this can take several minutes)..."
# Credentials exported by release.sh win; a keychain profile is the fallback.
if [ -n "${NOTARY_PASSWORD:-}" ]; then
  NOTARY_AUTH=(--apple-id "${NOTARY_APPLE_ID:?set NOTARY_APPLE_ID with NOTARY_PASSWORD}" \
               --team-id "${NOTARY_TEAM_ID:?set NOTARY_TEAM_ID with NOTARY_PASSWORD}" \
               --password "$NOTARY_PASSWORD")
else
  NOTARY_AUTH=(--keychain-profile "$NOTARY_PROFILE")
fi
xcrun notarytool submit "$DMG_OUT" "${NOTARY_AUTH[@]}" --wait

echo ""
echo "Stapling notarization ticket..."
xcrun stapler staple "$DMG_OUT"

echo ""
echo "Verifying notarization..."
xcrun stapler validate "$DMG_OUT"
spctl -a -t open --context context:primary-signature -v "$DMG_OUT"

echo ""
echo "Signing DMG with Sparkle (account: $SPARKLE_KEY_ACCOUNT)..."
SPARKLE_OUT="${DMG_OUT%.dmg}.sparkle.txt"
"$SIGN_UPDATE" --account "$SPARKLE_KEY_ACCOUNT" "$DMG_OUT" | tee "$SPARKLE_OUT"

echo ""
echo "============================================================"
echo "Release artifacts for v$VERSION"
echo "============================================================"
echo "  DMG:           $DMG_OUT"
echo "  Sparkle info:  $SPARKLE_OUT"
