#!/usr/bin/env bash
set -euo pipefail

PACKAGE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
STRICT_MODE="${1:-soft}"

run_bootstrap() {
  if [ ! -f "$PACKAGE_DIR/vendor/sqlcipher-amalgamation/sqlite3.c" ] || [ ! -f "$PACKAGE_DIR/vendor/sqlcipher-amalgamation/sqlite3.h" ]; then
    echo "SQLCipher amalgamation missing, preparing vendor files..."
    bash "$PACKAGE_DIR/scripts/prepare-amalgamation.sh"
  fi

  bash "$PACKAGE_DIR/scripts/ensure-electron-sqlcipher.sh"
}

if [ "$STRICT_MODE" = "strict" ]; then
  run_bootstrap
  exit 0
fi

if ! run_bootstrap; then
  echo "WARNING: SQLCipher bootstrap failed during postinstall."
  echo "Run manually: npm --prefix ../sqlcipher-adapter run sqlcipher:bootstrap:strict"
fi
