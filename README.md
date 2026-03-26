# @frag-ment/better-sqlite3-sqlcipher

SQLCipher-enabled adapter around `better-sqlite3`, plus helper scripts to bootstrap a working SQLCipher runtime (notably in Electron contexts).

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

## Install

```bash
npm i @frag-ment/better-sqlite3-sqlcipher
```

`postinstall` tries to bootstrap automatically (best effort). If it fails, install still succeeds and you can run strict mode manually.

For deterministic local/CI setup, run strict mode manually:

```bash
npm run sqlcipher:bootstrap:strict
```

Host app resolution:

- Scripts use `FRAGMENT_APP_ROOT` (or `INIT_CWD`) to find the host app root.
- If Electron version is not found in host `package.json`, set `ELECTRON_VERSION` explicitly.

## System dependencies

Linux build dependencies are the same as the desktop app native toolchain: `build-essential`, `python`, OpenSSL dev headers and `node-gyp` compatible environment.

## Runtime versions

- Node.js: `>=22.14.0`
- Electron host app: `35.1.4`
