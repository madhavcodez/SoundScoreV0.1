import assert from "node:assert/strict";
import test from "node:test";
import { logAuditEvent, type AuditEventType } from "../lib/audit";
import type { Db } from "../db/client";

const createMockDb = () => {
  const queries: Array<{ text: string; params: unknown[] }> = [];

  const mockDb: Db = {
    pool: {} as Db["pool"],
    redis: {} as Db["redis"],
    query: async (text: string, params?: unknown[]) => {
      queries.push({ text, params: params ?? [] });
      return { rows: [], rowCount: 0, command: "INSERT", oid: 0, fields: [] };
    },
    close: async () => {},
  };

  return { db: mockDb, queries };
};

test("logAuditEvent inserts with correct parameters", async () => {
  const { db, queries } = createMockDb();

  await logAuditEvent(db, {
    userId: "usr_123",
    type: "user.signup",
    details: { handle: "@testuser" },
    ipAddress: "127.0.0.1",
    userAgent: "TestAgent/1.0",
  });

  assert.equal(queries.length, 1);
  const [query] = queries;
  assert.ok(query.text.includes("INSERT INTO audit_events"));
  assert.ok((query.params[0] as string).startsWith("aud_"));
  assert.equal(query.params[1], "usr_123");
  assert.equal(query.params[2], "user.signup");
  assert.equal(query.params[3], JSON.stringify({ handle: "@testuser" }));
  assert.equal(query.params[4], "127.0.0.1");
  assert.equal(query.params[5], "TestAgent/1.0");
});

test("logAuditEvent uses defaults for optional fields", async () => {
  const { db, queries } = createMockDb();

  await logAuditEvent(db, {
    userId: "usr_456",
    type: "user.login",
  });

  assert.equal(queries.length, 1);
  const [query] = queries;
  assert.equal(query.params[3], "{}");
  assert.equal(query.params[4], null);
  assert.equal(query.params[5], null);
});

test("logAuditEvent scrubs sensitive fields from details", async () => {
  const { db, queries } = createMockDb();

  await logAuditEvent(db, {
    userId: "usr_789",
    type: "user.signup",
    details: {
      handle: "@test",
      password: "secret123",
      accessToken: "atk_leaked",
      refreshToken: "rtk_leaked",
      email: "user@example.com",
      safeField: "kept",
    },
  });

  assert.equal(queries.length, 1);
  const stored = JSON.parse(queries[0].params[3] as string);
  assert.equal(stored.handle, "@test");
  assert.equal(stored.safeField, "kept");
  assert.equal(stored.password, undefined);
  assert.equal(stored.accessToken, undefined);
  assert.equal(stored.refreshToken, undefined);
  assert.equal(stored.email, undefined);
});

test("AuditEventType accepts all valid event types", () => {
  const validTypes: AuditEventType[] = [
    "user.signup",
    "user.login",
    "user.logout",
    "provider.connect",
    "provider.disconnect",
    "account.export",
    "account.delete",
    "sync.start",
    "sync.complete",
    "sync.fail",
    "rating.create",
    "review.create",
    "review.update",
    "review.delete",
    "list.create",
    "admin.mapping_override",
  ];

  assert.equal(validTypes.length, 16);
  // Type-level assertion: this compiles only if all types are valid
  for (const t of validTypes) {
    assert.ok(typeof t === "string");
  }
});
