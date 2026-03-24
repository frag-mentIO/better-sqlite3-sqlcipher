#!/usr/bin/env bash
set -euo pipefail

PACKAGE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
VENDOR_DIR="$PACKAGE_DIR/vendor"
SRC_DIR="$VENDOR_DIR/sqlcipher-src"
OUT_DIR="$VENDOR_DIR/sqlcipher-amalgamation"
SQLCIPHER_REF="${SQLCIPHER_REF:-v4.6.1}"

mkdir -p "$VENDOR_DIR"

if [ ! -d "$SRC_DIR/.git" ]; then
  git clone https://github.com/sqlcipher/sqlcipher.git "$SRC_DIR"
fi

git -C "$SRC_DIR" fetch --tags --force
git -C "$SRC_DIR" checkout "$SQLCIPHER_REF"

(
  cd "$SRC_DIR"
  ./configure --with-tempstore=yes CFLAGS='-DSQLITE_HAS_CODEC' LDFLAGS='-lcrypto' --disable-tcl
  make sqlite3.c
)

mkdir -p "$OUT_DIR"
cp "$SRC_DIR/sqlite3.c" "$OUT_DIR/sqlite3.c"
cp "$SRC_DIR/sqlite3.h" "$OUT_DIR/sqlite3.h"
printf '%s\n' "$SQLCIPHER_REF" > "$OUT_DIR/VERSION.txt"

echo "Prepared SQLCipher amalgamation in $OUT_DIR"
