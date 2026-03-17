import assert from "node:assert/strict";
import test from "node:test";
import type { FastifyInstance } from "fastify";

let app: FastifyInstance | undefined;

const setup = async (): Promise<boolean> => {
  try {
    const { buildServer } = await import("../server");
    app = await buildServer();
    await app.db.query("SELECT 1");
    return true;
  } catch {
    return false;
  }
};

test("Error handling", async (t) => {
  const ready = await setup();
  if (!ready) {
    t.skip("Database or Redis not available");
    return;
  }

  t.after(async () => {
    if (app) await app.close();
  });

  const suffix = Date.now().toString(36);

  // Create a test user for authenticated tests
  let accessToken = "";
  let userId = "";

  await t.test("setup: create test user", async () => {
    const res = await app!.inject({
      method: "POST",
      url: "/v1/auth/signup",
      payload: {
        email: `err_${suffix}@test.local`,
        password: "TestPass123!",
        handle: `e_${suffix}`,
      },
    });
    assert.equal(res.statusCode, 200);
    const body = JSON.parse(res.payload);
    accessToken = body.accessToken;
    userId = body.userId;
  });

  await t.test("invalid JSON body returns 400", async () => {
    const res = await app!.inject({
      method: "POST",
      url: "/v1/auth/login",
      headers: { "content-type": "application/json" },
      payload: "{invalid-json",
    });

    assert.ok(res.statusCode >= 400 && res.statusCode < 500);
  });

  await t.test("missing auth header returns 401", async () => {
    const res = await app!.inject({
      method: "GET",
      url: "/v1/me",
    });

    assert.equal(res.statusCode, 401);
    const body = JSON.parse(res.payload);
    assert.equal(body.error.code, "UNAUTHORIZED");
  });

  await t.test("expired/invalid session returns 401", async () => {
    const res = await app!.inject({
      method: "GET",
      url: "/v1/me",
      headers: { authorization: "Bearer atk_invalidtoken12345678901234" },
    });

    assert.equal(res.statusCode, 401);
    const body = JSON.parse(res.payload);
    assert.equal(body.error.code, "UNAUTHORIZED");
  });

  await t.test("invalid album ID returns 404", async () => {
    const res = await app!.inject({
      method: "GET",
      url: "/v1/albums/nonexistent_album_id",
    });

    assert.equal(res.statusCode, 404);
    const body = JSON.parse(res.payload);
    assert.equal(body.error.code, "NOT_FOUND");
  });

  await t.test("duplicate rating on same album is idempotent", async () => {
    const key1 = `dup-rate1-${suffix}`;
    const key2 = `dup-rate2-${suffix}`;

    const res1 = await app!.inject({
      method: "POST",
      url: "/v1/ratings",
      headers: {
        authorization: `Bearer ${accessToken}`,
        "idempotency-key": key1,
      },
      payload: { albumId: "alb_1", value: 3.5 },
    });

    assert.equal(res1.statusCode, 200);

    // Second rating on same album with different key → upsert (idempotent at DB level)
    const res2 = await app!.inject({
      method: "POST",
      url: "/v1/ratings",
      headers: {
        authorization: `Bearer ${accessToken}`,
        "idempotency-key": key2,
      },
      payload: { albumId: "alb_1", value: 4.0 },
    });

    assert.equal(res2.statusCode, 200);
    const body2 = JSON.parse(res2.payload);
    assert.equal(body2.value, 4.0);
  });

  await t.test("SQL injection attempt in search is safely handled", async () => {
    const res = await app!.inject({
      method: "GET",
      url: "/v1/search?q=' OR 1=1; DROP TABLE users; --",
    });

    assert.equal(res.statusCode, 200);
    const body = JSON.parse(res.payload);
    assert.ok(Array.isArray(body.items));
  });

  await t.test("XSS in review body is stored as-is (JSON-safe)", async () => {
    const xssPayload = '<script>alert("xss")</script>';

    const res = await app!.inject({
      method: "POST",
      url: "/v1/reviews",
      headers: {
        authorization: `Bearer ${accessToken}`,
        "idempotency-key": `xss-review-${suffix}`,
      },
      payload: { albumId: "alb_2", body: xssPayload },
    });

    assert.equal(res.statusCode, 200);
    const body = JSON.parse(res.payload);
    // JSON API returns raw text — XSS is a frontend rendering concern
    assert.equal(body.body, xssPayload);
  });

  await t.test("missing idempotency key returns 400", async () => {
    const res = await app!.inject({
      method: "POST",
      url: "/v1/ratings",
      headers: { authorization: `Bearer ${accessToken}` },
      payload: { albumId: "alb_1", value: 3.0 },
    });

    assert.equal(res.statusCode, 400);
    const body = JSON.parse(res.payload);
    assert.equal(body.error.code, "IDEMPOTENCY_KEY_REQUIRED");
  });

  await t.test("validation: review body exceeding max length returns 400", async () => {
    const longBody = "x".repeat(5001);
    const res = await app!.inject({
      method: "POST",
      url: "/v1/reviews",
      headers: {
        authorization: `Bearer ${accessToken}`,
        "idempotency-key": `long-review-${suffix}`,
      },
      payload: { albumId: "alb_1", body: longBody },
    });

    // Zod validation should reject this
    assert.ok(res.statusCode >= 400 && res.statusCode < 500);
  });

  await t.test("validation: list title exceeding max length returns 400", async () => {
    const longTitle = "x".repeat(201);
    const res = await app!.inject({
      method: "POST",
      url: "/v1/lists",
      headers: {
        authorization: `Bearer ${accessToken}`,
        "idempotency-key": `long-list-${suffix}`,
      },
      payload: { title: longTitle },
    });

    assert.ok(res.statusCode >= 400 && res.statusCode < 500);
  });

  await t.test("validation: handle with invalid chars returns 400", async () => {
    const res = await app!.inject({
      method: "POST",
      url: "/v1/auth/signup",
      payload: {
        email: `bad_handle_${suffix}@test.local`,
        password: "TestPass123!",
        handle: "bad handle!@#",
      },
    });

    assert.ok(res.statusCode >= 400 && res.statusCode < 500);
  });

  // Cleanup test user
  await t.test("cleanup: delete test user", async () => {
    await app!.db.query("DELETE FROM users WHERE id = $1", [userId]);
  });
});
