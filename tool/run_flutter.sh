#!/usr/bin/env bash
set -euo pipefail

if ! command -v flutter >/dev/null 2>&1; then
  echo "flutter is not installed or not on PATH" >&2
  exit 1
fi

flutter run "$@"
