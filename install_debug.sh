#!/usr/bin/env bash
# Debug-Build per flutter run (Hot Reload) – siehe `app --help`.
exec app "$(dirname "$0")" run "$@"
