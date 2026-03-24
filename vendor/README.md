# SQLCipher Adapter Vendor Policy

This vendor directory is private to `@fragment/sqlcipher-adapter`.

## Versioned artifacts

Commit only:

- `vendor/sqlcipher-amalgamation/sqlite3.c`
- `vendor/sqlcipher-amalgamation/sqlite3.h`
- `vendor/sqlcipher-amalgamation/VERSION.txt`

## Local-only helper sources

Generated and ignored:

- `vendor/sqlcipher-src`

Refresh command:

```bash
npm --prefix ./packages/sqlcipher-adapter run sqlcipher:prepare
```
