# @fragment/sqlcipher-adapter

Internal package that isolates SQLCipher runtime access for the desktop app.

## Role

- Provides a small typed adapter around `better-sqlite3` + SQLCipher PRAGMAs.
- Keeps native encryption concerns outside app business/UI layers.
- Makes extraction to a dedicated repository straightforward later.

## Public API

- `openEncryptedDatabase(options)`
- `closeDatabase()`
- `runMigrations(migrate)`
- `isCipherAvailable(databaseCtor?)`
- `applySecurityPragmas(db, passphrase, options?)`

## Scripts

- `npm run sqlcipher:bootstrap`: auto-prepare + ensure (best effort).
- `npm run sqlcipher:bootstrap:strict`: auto-prepare + ensure (fails on error, for CI/release).
- `npm run sqlcipher:prepare`: prepare SQLCipher amalgamation into `packages/sqlcipher-adapter/vendor/sqlcipher-amalgamation`.
- `npm run sqlcipher:ensure`: rebuild only when Electron/version/vendor hash changed.
- `npm run sqlcipher:rebuild`: rebuild `better-sqlite3` for Electron against SQLCipher.
- `npm run sqlcipher:check`: run runtime health check (`PRAGMA cipher_version`).
- `npm run test`: run adapter unit tests.

`postinstall` runs `sqlcipher:bootstrap` automatically so local installs self-heal whenever possible.

## System dependencies

Linux build dependencies are the same as the desktop app native toolchain: `build-essential`, `python`, OpenSSL dev headers and `node-gyp` compatible environment.

## Runtime versions

- Node.js: `22.14.0`
- Electron host app: `35.1.4`

## Future extraction strategy

1. Keep only adapter + tests + scripts in this package.
2. Move vendor references to environment variables or a companion tooling package.
3. Publish as a private package (or separate repo) and replace local file dependency in the app.
