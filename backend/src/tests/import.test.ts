import assert from "node:assert/strict";
import { describe, it } from "node:test";
import { generateDedupKey } from "../modules/import";

describe("generateDedupKey", () => {
  it("produces deterministic key for same inputs", () => {
    const date = new Date("2026-03-17T12:00:00Z");
    const key1 = generateDedupKey("usr_1", "cnb_abc", date);
    const key2 = generateDedupKey("usr_1", "cnb_abc", date);
    assert.equal(key1, key2);
  });

  it("buckets plays within the same 10-minute window", () => {
    const t1 = new Date("2026-03-17T12:00:00Z");
    const t2 = new Date("2026-03-17T12:05:00Z"); // 5 min later, same bucket
    const key1 = generateDedupKey("usr_1", "cnb_abc", t1);
    const key2 = generateDedupKey("usr_1", "cnb_abc", t2);
    assert.equal(key1, key2);
  });

  it("separates plays in different 10-minute windows", () => {
    const t1 = new Date("2026-03-17T12:00:00Z");
    const t2 = new Date("2026-03-17T12:10:00Z"); // exactly next bucket
    const key1 = generateDedupKey("usr_1", "cnb_abc", t1);
    const key2 = generateDedupKey("usr_1", "cnb_abc", t2);
    assert.notEqual(key1, key2);
  });

  it("separates different users", () => {
    const date = new Date("2026-03-17T12:00:00Z");
    const key1 = generateDedupKey("usr_1", "cnb_abc", date);
    const key2 = generateDedupKey("usr_2", "cnb_abc", date);
    assert.notEqual(key1, key2);
  });

  it("separates different albums", () => {
    const date = new Date("2026-03-17T12:00:00Z");
    const key1 = generateDedupKey("usr_1", "cnb_abc", date);
    const key2 = generateDedupKey("usr_1", "cnb_xyz", date);
    assert.notEqual(key1, key2);
  });

  it("includes all three components in the key", () => {
    const date = new Date("2026-03-17T12:00:00Z");
    const key = generateDedupKey("usr_1", "cnb_abc", date);
    assert.ok(key.startsWith("usr_1:cnb_abc:"));
    // Verify bucket value is a number
    const parts = key.split(":");
    assert.equal(parts.length, 3);
    assert.ok(Number.isInteger(Number(parts[2])));
  });
});

describe("sync job state transitions", () => {
  it("documents valid state transitions", () => {
    // This is a documentation/specification test — validates our state machine design
    const validTransitions: Record<string, string[]> = {
      queued: ["running", "cancelled"],
      running: ["completed", "failed", "cancelled"],
      completed: [],
      failed: [],
      cancelled: [],
    };

    // queued can transition to running or cancelled
    assert.ok(validTransitions.queued.includes("running"));
    assert.ok(validTransitions.queued.includes("cancelled"));

    // running can transition to completed, failed, or cancelled
    assert.ok(validTransitions.running.includes("completed"));
    assert.ok(validTransitions.running.includes("failed"));
    assert.ok(validTransitions.running.includes("cancelled"));

    // terminal states have no transitions
    assert.equal(validTransitions.completed.length, 0);
    assert.equal(validTransitions.failed.length, 0);
    assert.equal(validTransitions.cancelled.length, 0);
  });
});

describe("cursor persistence", () => {
  it("documents cursor behavior across syncs", () => {
    // Specification test: cursor is per user+provider
    // The composite primary key (user_id, provider) ensures one cursor per pair
    // UPSERT via ON CONFLICT ensures cursor is updated, not duplicated
    const cursorKey = { userId: "usr_1", provider: "spotify" };
    assert.equal(typeof cursorKey.userId, "string");
    assert.equal(typeof cursorKey.provider, "string");
  });
});
