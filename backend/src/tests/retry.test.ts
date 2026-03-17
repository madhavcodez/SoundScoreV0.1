import assert from "node:assert/strict";
import test from "node:test";
import { withRetry } from "../lib/retry";

test("withRetry returns result on first success", async () => {
  const result = await withRetry(async () => 42);
  assert.equal(result, 42);
});

test("withRetry retries on failure then succeeds", async () => {
  let attempts = 0;
  const result = await withRetry(
    async () => {
      attempts++;
      if (attempts < 3) throw new Error("fail");
      return "ok";
    },
    { maxAttempts: 3, backoffMs: 1 },
  );

  assert.equal(result, "ok");
  assert.equal(attempts, 3);
});

test("withRetry throws after max attempts", async () => {
  let attempts = 0;
  await assert.rejects(
    () =>
      withRetry(
        async () => {
          attempts++;
          throw new Error("persistent failure");
        },
        { maxAttempts: 3, backoffMs: 1 },
      ),
    { message: "persistent failure" },
  );

  assert.equal(attempts, 3);
});

test("withRetry respects maxBackoffMs cap", async () => {
  let attempts = 0;
  const start = Date.now();

  await assert.rejects(
    () =>
      withRetry(
        async () => {
          attempts++;
          throw new Error("fail");
        },
        { maxAttempts: 4, backoffMs: 1, maxBackoffMs: 5 },
      ),
    { message: "fail" },
  );

  const elapsed = Date.now() - start;
  assert.equal(attempts, 4);
  // With maxBackoff=5ms and backoff=1ms, total delay should be small
  assert.ok(elapsed < 500, `Expected fast completion but took ${elapsed}ms`);
});

test("withRetry calls onRetry callback", async () => {
  const retries: number[] = [];
  let attempts = 0;

  await assert.rejects(
    () =>
      withRetry(
        async () => {
          attempts++;
          throw new Error("fail");
        },
        {
          maxAttempts: 3,
          backoffMs: 1,
          onRetry: (attempt) => retries.push(attempt),
        },
      ),
    { message: "fail" },
  );

  assert.deepEqual(retries, [1, 2]);
});

test("withRetry uses default options", async () => {
  const result = await withRetry(async () => "default-ok");
  assert.equal(result, "default-ok");
});
