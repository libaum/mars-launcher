#!/usr/bin/env bash
# Release bauen, archivieren, installieren – siehe `app --help`.
#   ./install_release.sh [list|restore [versionCode]]
exec app "$(dirname "$0")" "$@"
