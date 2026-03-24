import type BetterSqlite3 from 'better-sqlite3';

export type BetterSqlite3Database = BetterSqlite3.Database;
export type BetterSqlite3Ctor = new (path: string) => BetterSqlite3Database;

export type SecurityPragmaOptions = {
  kdfIter?: number;
  foreignKeys?: boolean;
  secureDelete?: boolean;
  journalMode?: 'DELETE' | 'TRUNCATE' | 'PERSIST' | 'MEMORY' | 'WAL' | 'OFF';
};

export type OpenEncryptedDatabaseOptions = SecurityPragmaOptions & {
  dbPath: string;
  passphrase: string;
  databaseCtor?: BetterSqlite3Ctor;
};

const DEFAULT_KDF_ITER = 256000;
let activeDb: BetterSqlite3Database | null = null;

export function openEncryptedDatabase(options: OpenEncryptedDatabaseOptions): BetterSqlite3Database {
  if (activeDb) return activeDb;
  const db = new (options.databaseCtor ?? loadDatabaseCtor())(options.dbPath);
  try {
    applySecurityPragmas(db, options.passphrase, options);
    assertCipherAvailable(db);
  } catch (err) {
    db.close();
    throw err;
  }
  activeDb = db;
  return db;
}

export function closeDatabase(): void {
  if (!activeDb) return;
  activeDb.close();
  activeDb = null;
}

export function runMigrations(migrate: (db: BetterSqlite3Database) => void = () => {}): void {
  if (!activeDb) throw new Error('Database is not open. Call openEncryptedDatabase() first.');
  migrate(activeDb);
}

export function isCipherAvailable(databaseCtor?: BetterSqlite3Ctor): boolean {
  const DbCtor = databaseCtor ?? loadDatabaseCtor();
  let db: BetterSqlite3Database | null = null;
  try {
    db = new DbCtor(':memory:');
    db.pragma("key='probe'");
    const cipherVersion = db.pragma('cipher_version', { simple: true }) as string | undefined;
    return Boolean(cipherVersion);
  } catch {
    return false;
  } finally {
    db?.close();
  }
}

export function applySecurityPragmas(
  db: BetterSqlite3Database,
  passphrase: string,
  options?: SecurityPragmaOptions,
): void {
  const escapedKey = passphrase.replace(/'/g, "''");
  db.pragma(`key='${escapedKey}'`);
  db.pragma(`kdf_iter=${options?.kdfIter ?? DEFAULT_KDF_ITER}`);
  db.pragma(`journal_mode = ${options?.journalMode ?? 'WAL'}`);
  db.pragma(`foreign_keys = ${options?.foreignKeys === false ? 'OFF' : 'ON'}`);
  db.pragma(`secure_delete = ${options?.secureDelete === false ? 'OFF' : 'ON'}`);
}

function assertCipherAvailable(db: BetterSqlite3Database): void {
  const cipherVersion = db.pragma('cipher_version', { simple: true }) as string | undefined;
  if (!cipherVersion) {
    throw new Error(
      'SQLCipher is not available in current SQLite runtime. Build better-sqlite3 against SQLCipher before starting the app.',
    );
  }
}

function loadDatabaseCtor(): BetterSqlite3Ctor {
  // eslint-disable-next-line @typescript-eslint/no-require-imports
  const mod = require('better-sqlite3') as BetterSqlite3Ctor | { default: BetterSqlite3Ctor };
  if (typeof mod === 'function') return mod;
  if (mod && typeof mod.default === 'function') return mod.default;
  throw new Error('Failed to load better-sqlite3');
}
