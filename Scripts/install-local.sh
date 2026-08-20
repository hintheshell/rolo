#!/bin/bash
# Build and replace the installed release-channel app. Usage: ./Scripts/install-local.sh
set -euo pipefail

cd "$(dirname "$0")/.." || exit 1
export DEVELOPER_DIR="${DEVELOPER_DIR:-/Applications/Xcode.app/Contents/Developer}"
IDENTITY="Rolo Self-Signed"
DERIVED="build/DerivedData"
APP="$DERIVED/Build/Products/Release/Rolo.app"
TARGET="/Applications/Rolo.app"
PROCESS_PATTERN='^/Applications/Rolo\.app/Contents/MacOS/Rolo$'
ALLOW_SIGNING_CHANGE=false

if [[ "${1:-}" == "--allow-signing-change" ]]; then
    ALLOW_SIGNING_CHANGE=true
elif (( $# > 0 )); then
    echo "Usage: $0 [--allow-signing-change]" >&2
    exit 2
fi

if ! security find-identity -p codesigning | grep -q "$IDENTITY"; then
    echo "✗ '$IDENTITY' code-signing identity not found — create it once (docs/signing.md)." >&2
    exit 1
fi

if [[ ! -w /Applications ]]; then
    echo "✗ /Applications is not writable by the current user." >&2
    exit 1
fi

echo "▸ Building signed Rolo.app (Release)…"
xcodebuild -project Tinycast.xcodeproj -scheme Tinycast -configuration Release \
    -derivedDataPath "$DERIVED" \
    CODE_SIGN_STYLE=Manual CODE_SIGN_IDENTITY="$IDENTITY" OTHER_CODE_SIGN_FLAGS="--timestamp=none" \
    build

if [[ ! -d "$APP" ]]; then
    echo "✗ Build completed without producing $APP." >&2
    exit 1
fi

BUNDLE_ID="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleIdentifier' "$APP/Contents/Info.plist")"
if [[ "$BUNDLE_ID" != "com.hintheshell.rolo" ]]; then
    echo "✗ Refusing to install unexpected bundle id '$BUNDLE_ID'." >&2
    exit 1
fi

WORK="$(mktemp -d /Applications/.rolo-install.XXXXXX)"
STAGED="$WORK/Rolo.app"
BACKUP="$WORK/previous.app"

cleanup() {
    local status=$?
    trap - EXIT
    if [[ -e "$BACKUP" && ! -e "$TARGET" ]]; then
        mv "$BACKUP" "$TARGET" || true
    fi
    rm -rf "$WORK"
    exit "$status"
}
trap cleanup EXIT

echo "▸ Staging and verifying Rolo.app…"
ditto "$APP" "$STAGED"
codesign --verify --deep --strict "$STAGED"

if [[ -e "$TARGET" || -L "$TARGET" ]]; then
    INSTALLED_REQUIREMENT="$(codesign -d -r- "$TARGET" 2>&1 | sed -n 's/^designated => //p')"
    STAGED_REQUIREMENT="$(codesign -d -r- "$STAGED" 2>&1 | sed -n 's/^designated => //p')"
    if [[ "$INSTALLED_REQUIREMENT" != "$STAGED_REQUIREMENT" && "$ALLOW_SIGNING_CHANGE" == false ]]; then
        echo "✗ Signing identity differs from the installed app; replacement could reset macOS grants." >&2
        echo "  Import the original identity or explicitly pass --allow-signing-change once." >&2
        exit 1
    fi
fi

if pgrep -f "$PROCESS_PATTERN" >/dev/null; then
    echo "▸ Stopping installed Rolo…"
    pkill -TERM -f "$PROCESS_PATTERN"
    for _ in {1..50}; do
        if ! pgrep -f "$PROCESS_PATTERN" >/dev/null; then
            break
        fi
        sleep 0.1
    done
    if pgrep -f "$PROCESS_PATTERN" >/dev/null; then
        echo "✗ Rolo did not quit; the installed app was not changed." >&2
        exit 1
    fi
fi

echo "▸ Replacing $TARGET…"
if [[ -e "$TARGET" || -L "$TARGET" ]]; then
    mv "$TARGET" "$BACKUP"
fi
mv "$STAGED" "$TARGET"
rm -rf "$WORK"
trap - EXIT

open "$TARGET"
echo "✓ Installed and launched $TARGET"
echo "  Homebrew still tracks its last cask version; a future upgrade or reinstall can replace this build."
