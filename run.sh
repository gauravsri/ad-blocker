#!/usr/bin/env bash
set -e

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"
cd "$DIR"

echo "Building AdBlocker..."
swift build -c release

echo "Launching YouTube Ad Blocker..."
exec .build/release/AdBlocker
