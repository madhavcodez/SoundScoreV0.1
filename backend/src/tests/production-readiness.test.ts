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
    if (app) await app.close().catch(() => {});
    app = undefined;
    return false;
  }
};

test("Production readiness checks", async (t) => {
  const ready = await setup();
  if (!ready) {
    t.skip("Database or Redis not available");
    return;
  }

  t.after(async () => {
    if (app) await app.close();
  });

  await t.test("health check returns ok when services are up", async () => {
    const res = await app!.inject({ method: "GET", url: "/health" });
    assert.equal(res.statusCode, 200);
    const body = JSON.parse(res.payload);
    assert.equal(body.status, "ok");
    assert.equal(body.checks.postgres, "up");
    assert.equal(body.checks.redis, "up");
  });

  await t.test("security headers are present", async () => {
    const res = await app!.inject({ method: "GET", url: "/health" });
    // Helmet should add these headers
    assert.ok(res.headers["x-content-type-options"]);
    assert.ok(res.headers["x-frame-options"]);
  });

  await t.test("OpenAPI docs endpoint is reachable", async () => {
    const res = await app!.inject({ method: "GET", url: "/docs/json" });
    assert.equal(res.statusCode, 200);
    const body = JSON.parse(res.payload);
    assert.equal(body.openapi, "3.1.0");
    assert.equal(body.info.title, "SoundScore API");
  });

  await t.test("session expiry column exists in database", async () => {
    const result = await app!.db.query(
      `SELECT column_name FROM information_schema.columns
       WHERE table_name = 'sessions' AND column_name = 'expires_at'`,
    );
    assert.equal(result.rowCount, 1);
  });

  await t.test("search_vector column exists on albums", async () => {
    const result = await app!.db.query(
      `SELECT column_name FROM information_schema.columns
       WHERE table_name = 'albums' AND column_name = 'search_vector'`,
    );
    assert.equal(result.rowCount, 1);
  });

  await t.test("required indexes exist", async () => {
    const indexes = await app!.db.query<{ indexname: string }>(
      `SELECT indexname FROM pg_indexes WHERE tablename IN ('ratings', 'reviews', 'activity_events', 'sessions')`,
    );
    const names = indexes.rows.map((r) => r.indexname);
    assert.ok(names.includes("idx_ratings_album"), "idx_ratings_album missing");
    assert.ok(names.includes("idx_reviews_album"), "idx_reviews_album missing");
    assert.ok(names.includes("idx_activity_created"), "idx_activity_created missing");
    assert.ok(names.includes("idx_sessions_expires"), "idx_sessions_expires missing");
  });

  const suffix = Date.now().toString(36);

  await t.test("pagination: feed accepts cursor and limit params", async () => {
    // Create a test user
    const signupRes = await app!.inject({
      method: "POST",
      url: "/v1/auth/signup",
      payload: {
        email: `pag_${suffix}@test.local`,
        password: "TestPass123!",
        handle: `pg${suffix}`,
      },
    });
    assert.equal(signupRes.statusCode, 201);
    const { accessToken, userId } = JSON.parse(signupRes.payload);

    const res = await app!.inject({
      method: "GET",
      url: "/v1/feed?limit=5",
      headers: { authorization: `Bearer ${accessToken}` },
    });

    assert.equal(res.statusCode, 200);
    const body = JSON.parse(res.payload);
    assert.ok(Array.isArray(body.items));
    assert.ok("nextCursor" in body);

    // Cleanup
    await app!.db.query("DELETE FROM users WHERE id = $1", [userId]);
  });

  await t.test("search pagination works", async () => {
    const res = await app!.inject({
      method: "GET",
      url: "/v1/search?limit=2",
    });

    assert.equal(res.statusCode, 200);
    const body = JSON.parse(res.payload);
    assert.ok(Array.isArray(body.items));
    assert.ok("nextCursor" in body);
  });

  await t.test("signup returns 201 Created", async () => {
    const res = await app!.inject({
      method: "POST",
      url: "/v1/auth/signup",
      payload: {
        email: `status_${suffix}@test.local`,
        password: "TestPass123!",
        handle: `s_${suffix}`,
      },
    });
    assert.equal(res.statusCode, 201);
    const { userId } = JSON.parse(res.payload);
    await app!.db.query("DELETE FROM users WHERE id = $1", [userId]);
  });

  await t.test("sanitization: HTML stripped from review body", async () => {
    // Create a user to test with
    const signupRes = await app!.inject({
      method: "POST",
      url: "/v1/auth/signup",
      payload: {
        email: `san_${suffix}@test.local`,
        password: "TestPass123!",
        handle: `sn${suffix}`,
      },
    });
    const { accessToken, userId } = JSON.parse(signupRes.payload);

    const res = await app!.inject({
      method: "POST",
      url: "/v1/reviews",
      headers: {
        authorization: `Bearer ${accessToken}`,
        "idempotency-key": `san-review-${suffix}`,
      },
      payload: { albumId: "alb_1", body: "Great <b>album</b>!" },
    });

    assert.ok(res.statusCode >= 200 && res.statusCode <= 201);
    const body = JSON.parse(res.payload);
    assert.equal(body.body, "Great album!");

    await app!.db.query("DELETE FROM users WHERE id = $1", [userId]);
  });
});
