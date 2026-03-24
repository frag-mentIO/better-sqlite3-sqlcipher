#!/usr/bin/env bash
set -euo pipefail

PACKAGE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
REQUEST_MODE="${1:-soft}"
STRICT_MODE="soft"
IS_POSTINSTALL="0"

if [ "$REQUEST_MODE" = "strict" ]; then
  STRICT_MODE="strict"
elif [ "$REQUEST_MODE" = "postinstall" ]; then
  IS_POSTINSTALL="1"
fi

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

if [ "$IS_POSTINSTALL" = "1" ] && [ "${SQLCIPHER_AUTO_BOOTSTRAP:-0}" != "1" ]; then
  echo "Skipping SQLCipher bootstrap during postinstall (set SQLCIPHER_AUTO_BOOTSTRAP=1 to enable)."
  echo "Run manually when needed: npm run sqlcipher:bootstrap:strict"
  exit 0
fi

if ! run_bootstrap; then
  echo "WARNING: SQLCipher bootstrap failed during postinstall."
  echo "Run manually: npm run sqlcipher:bootstrap:strict"
fi
