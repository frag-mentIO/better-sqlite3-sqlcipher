#!/usr/bin/env bash
set -euo pipefail

PACKAGE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PACK_DIR="$PACKAGE_DIR/build/packages"

mkdir -p "$PACK_DIR"

echo "Bumping package patch version..."
npm --prefix "$PACKAGE_DIR" version patch --no-git-tag-version

echo "Packing tarball into $PACK_DIR..."
npm --prefix "$PACKAGE_DIR" pack --pack-destination "$PACK_DIR"
