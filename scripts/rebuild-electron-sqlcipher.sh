#!/usr/bin/env bash
set -euo pipefail

PACKAGE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ROOT_DIR="${FRAGMENT_APP_ROOT:-${INIT_CWD:-}}"
if [ -z "$ROOT_DIR" ] || [ ! -f "$ROOT_DIR/package.json" ]; then
  echo "Unable to resolve host app root."
  echo "Set FRAGMENT_APP_ROOT to the app directory (must contain package.json)."
  exit 1
fi
AMALGAMATION_DIR="$PACKAGE_DIR/vendor/sqlcipher-amalgamation"
ELECTRON_VERSION="${ELECTRON_VERSION:-}"

if [ -z "$ELECTRON_VERSION" ]; then
  ELECTRON_VERSION="$(node -e "const path=require('path'); const root=process.argv[1]; const pkg=require(path.join(root,'package.json')); const v=(pkg.devDependencies&&pkg.devDependencies.electron)||(pkg.dependencies&&pkg.dependencies.electron)||''; process.stdout.write(v||'');" "$ROOT_DIR")"
fi

if [ -z "$ELECTRON_VERSION" ]; then
  echo "Unable to resolve Electron version from $ROOT_DIR/package.json."
  echo "Set ELECTRON_VERSION explicitly, e.g. ELECTRON_VERSION=35.1.4 npm run sqlcipher:rebuild"
  exit 1
fi

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
