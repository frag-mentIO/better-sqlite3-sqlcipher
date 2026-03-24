#!/usr/bin/env bash
set -euo pipefail

PACKAGE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ROOT_DIR="${FRAGMENT_APP_ROOT:-${INIT_CWD:-}}"
if [ -z "$ROOT_DIR" ] || [ ! -f "$ROOT_DIR/package.json" ]; then
  ROOT_DIR="$(cd "$PACKAGE_DIR/../desktop" && pwd)"
fi
AMALGAMATION_DIR="$PACKAGE_DIR/vendor/sqlcipher-amalgamation"
ELECTRON_VERSION="$(node -p "require('$ROOT_DIR/package.json').devDependencies.electron")"

if [ ! -f "$AMALGAMATION_DIR/sqlite3.c" ] || [ ! -f "$AMALGAMATION_DIR/sqlite3.h" ]; then
  echo "Missing SQLCipher amalgamation files in $AMALGAMATION_DIR"
  echo "Run: npm run sqlcipher:prepare"
  exit 1
fi

echo "Rebuilding better-sqlite3 for Electron $ELECTRON_VERSION using SQLCipher amalgamation..."

(
  cd "$ROOT_DIR/node_modules/better-sqlite3"
  CFLAGS='-DSQLITE_HAS_CODEC -DSQLITE_TEMP_STORE=2 -DSQLCIPHER_CRYPTO_OPENSSL -DHAVE_STDINT_H=1' \
  CXXFLAGS='-DSQLITE_HAS_CODEC -DSQLITE_TEMP_STORE=2 -DSQLCIPHER_CRYPTO_OPENSSL -DHAVE_STDINT_H=1' \
  LDFLAGS='-Wl,--no-as-needed -lcrypto' \
  npx node-gyp rebuild \
    --release \
    --runtime=electron \
    --target="$ELECTRON_VERSION" \
    --dist-url=https://electronjs.org/headers \
    --sqlite3="$AMALGAMATION_DIR"
)

echo "SQLCipher rebuild done."
