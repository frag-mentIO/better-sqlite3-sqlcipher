import { describe, expect, it } from 'vitest';
import {
  applySecurityPragmas,
  closeDatabase,
  isCipherAvailable,
  openEncryptedDatabase,
  runMigrations,
} from '../src';

type FakeDb = {
  closed: boolean;
  pragmaCalls: string[];
  execCalls: string[];
  close: () => void;
  pragma: (query: string, options?: { simple?: boolean }) => unknown;
  exec: (query: string) => void;
};

function createFakeDb(cipherVersion: string | undefined): FakeDb {
  return {
    closed: false,
    pragmaCalls: [],
    execCalls: [],
    close() {
      this.closed = true;
    },
    pragma(query: string, options?: { simple?: boolean }) {
      this.pragmaCalls.push(query);
      if (query === 'cipher_version' && options?.simple) return cipherVersion;
      return undefined;
    },
    exec(query: string) {
      this.execCalls.push(query);
    },
  };
}

describe('sqlcipher adapter', () => {
  it('opens encrypted database and applies expected PRAGMA initialization', () => {
    const fakeDb = createFakeDb('4.6.1');
    const FakeCtor = class {
      constructor(_path: string) {
        return fakeDb;
      }
    } as unknown as new (path: string) => any;

    const db = openEncryptedDatabase({
      dbPath: ':memory:',
      passphrase: "abc'def",
      databaseCtor: FakeCtor,
    });

    expect(db).toBe(fakeDb);
    expect(fakeDb.pragmaCalls).toContain("key='abc''def'");
    expect(fakeDb.pragmaCalls).toContain('kdf_iter=256000');
    expect(fakeDb.pragmaCalls).toContain('journal_mode = WAL');
    expect(fakeDb.pragmaCalls).toContain('foreign_keys = ON');
    expect(fakeDb.pragmaCalls).toContain('secure_delete = ON');
    closeDatabase();
    expect(fakeDb.closed).toBe(true);
  });

  it('fails explicitly when SQLCipher is unavailable', () => {
    const fakeDb = createFakeDb(undefined);
    const FakeCtor = class {
      constructor(_path: string) {
        return fakeDb;
      }
    } as unknown as new (path: string) => any;

    expect(() =>
      openEncryptedDatabase({
        dbPath: ':memory:',
        passphrase: 'secret',
        databaseCtor: FakeCtor,
      }),
    ).toThrow(/SQLCipher is not available/);
  });

  it('runs migration callback on active database', () => {
    const fakeDb = createFakeDb('4.6.1');
    const FakeCtor = class {
      constructor(_path: string) {
        return fakeDb;
      }
    } as unknown as new (path: string) => any;

    openEncryptedDatabase({ dbPath: ':memory:', passphrase: 'secret', databaseCtor: FakeCtor });
    runMigrations((db: any) => {
      db.exec('CREATE TABLE IF NOT EXISTS test_table(id INTEGER PRIMARY KEY)');
    });
    expect(fakeDb.execCalls[0]).toContain('CREATE TABLE IF NOT EXISTS test_table');
    closeDatabase();
  });

  it('checks cipher availability via health check', () => {
    const fakeDb = createFakeDb('4.6.1');
    const FakeCtor = class {
      constructor(_path: string) {
        return fakeDb;
      }
    } as unknown as new (path: string) => any;
    expect(isCipherAvailable(FakeCtor)).toBe(true);
  });

  it('exposes pragma helper for custom settings', () => {
    const fakeDb = createFakeDb('4.6.1');
    applySecurityPragmas(fakeDb as any, 'secret', {
      kdfIter: 1000,
      foreignKeys: false,
      secureDelete: false,
      journalMode: 'DELETE',
    });
    expect(fakeDb.pragmaCalls).toEqual([
      "key='secret'",
      'kdf_iter=1000',
      'journal_mode = DELETE',
      'foreign_keys = OFF',
      'secure_delete = OFF',
    ]);
  });
});
