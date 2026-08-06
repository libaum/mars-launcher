#!/usr/bin/env bash
set -euo pipefail
# Admin-only settings transfer for Mars Launcher via adb.
# Moves the launcher's settings JSON between the device and this machine so a
# known-good configuration can be backed up and pushed onto another install.
#
# In the launcher (private Mars apps must be unlocked first), type into the app
# search field:
#   #exportsettings   dump current settings to the device
#   #importsettings   load settings from the device (then restart the launcher)
#
# Usage:
#   ./settings.sh pull [file] [--debug]   copy settings off the device (default: mars_settings.json)
#   ./settings.sh push [file] [--debug]   copy settings onto the device, ready for #importsettings
#
# --debug targets the debug build (com.cloudcatcher.mars_launcher.debug) instead of release.
cd "$(dirname "$0")"

ARGS=()
DEBUG=false
for arg in "$@"; do
  if [ "$arg" = "--debug" ]; then
    DEBUG=true
  else
    ARGS+=("$arg")
  fi
done
set -- "${ARGS[@]+"${ARGS[@]}"}"

PKG="com.cloudcatcher.mars_launcher"
$DEBUG && PKG="com.cloudcatcher.mars_launcher.debug"
REMOTE="/sdcard/Android/data/$PKG/files/mars_settings.json"
LOCAL="${2:-mars_settings.json}"

require_device() {
  if [ -z "$(adb devices | sed '1d' | grep -w device || true)" ]; then
    echo "No device connected (check 'adb devices')." >&2
    exit 1
  fi
}

require_device
case "${1:-}" in
  pull)
    adb pull "$REMOTE" "$LOCAL"
    echo "==> Pulled settings to $LOCAL"
    ;;
  push)
    [ -f "$LOCAL" ] || { echo "Local file '$LOCAL' not found." >&2; exit 1; }
    adb push "$LOCAL" "$REMOTE"
    echo "==> Pushed $LOCAL to device. In the launcher: type #importsettings, then restart it."
    ;;
  *)
    echo "Usage: $0 [pull|push] [file]" >&2
    exit 1
    ;;
esac
