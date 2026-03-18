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

test("Integration: full user journey", async (t) => {
  const ready = await setup();
  if (!ready) {
    t.skip("Database or Redis not available");
    return;
  }

  t.after(async () => {
    if (app) await app.close();
  });

  const suffix = Date.now().toString(36);
  const email = `integ_${suffix}@test.local`;
  const password = "TestPass123!";
  const handle = `t_${suffix}`;

  let accessToken = "";
  let refreshToken = "";
  let userId = "";
  const albumId = "alb_1";
  let reviewId = "";
  let listId = "";
  let activityId = "";

  // Step 1: Signup
  await t.test("1. signup creates user", async () => {
    const res = await app!.inject({
      method: "POST",
      url: "/v1/auth/signup",
      payload: { email, password, handle },
    });

    assert.equal(res.statusCode, 201);
    const body = JSON.parse(res.payload);
    assert.ok(body.accessToken);
    assert.ok(body.refreshToken);
    assert.ok(body.userId);
    assert.equal(body.handle, `@${handle}`);

    accessToken = body.accessToken;
    refreshToken = body.refreshToken;
    userId = body.userId;

    const user = await app!.db.query("SELECT id, email FROM users WHERE id = $1", [userId]);
    assert.equal(user.rowCount, 1);
    assert.equal(user.rows[0].email, email);
  });

  // Step 2: Login
  await t.test("2. login returns tokens", async () => {
    const res = await app!.inject({
      method: "POST",
      url: "/v1/auth/login",
      payload: { email, password },
    });

    assert.equal(res.statusCode, 200);
    const body = JSON.parse(res.payload);
    assert.ok(body.accessToken);
    assert.ok(body.refreshToken);
    assert.equal(body.userId, userId);

    accessToken = body.accessToken;
    refreshToken = body.refreshToken;
  });

  // Step 3: Search albums
  await t.test("3. search albums returns results", async () => {
    const res = await app!.inject({
      method: "GET",
      url: "/v1/search?q=chromakopia",
    });

    assert.equal(res.statusCode, 200);
    const body = JSON.parse(res.payload);
    assert.ok(Array.isArray(body.items));
    assert.ok(body.items.length > 0);
    assert.equal(body.items[0].id, albumId);
  });

  // Step 4: Create rating (idempotent)
  await t.test("4. create rating and verify idempotency", async () => {
    const idempotencyKey = `rate-${suffix}`;

    const res = await app!.inject({
      method: "POST",
      url: "/v1/ratings",
      headers: {
        authorization: `Bearer ${accessToken}`,
        "idempotency-key": idempotencyKey,
      },
      payload: { albumId, value: 4.5 },
    });

    assert.equal(res.statusCode, 201);
    const body = JSON.parse(res.payload);
    assert.equal(body.albumId, albumId);
    assert.equal(body.value, 4.5);
    assert.equal(body.userId, userId);

    // Verify idempotency: same key returns same result
    const res2 = await app!.inject({
      method: "POST",
      url: "/v1/ratings",
      headers: {
        authorization: `Bearer ${accessToken}`,
        "idempotency-key": idempotencyKey,
      },
      payload: { albumId, value: 4.5 },
    });

    assert.equal(res2.statusCode, 200);
    const body2 = JSON.parse(res2.payload);
    assert.equal(body2.albumId, body.albumId);
    assert.equal(body2.value, body.value);
  });

  // Step 5: Create review
  await t.test("5. create review and verify stored", async () => {
    const res = await app!.inject({
      method: "POST",
      url: "/v1/reviews",
      headers: {
        authorization: `Bearer ${accessToken}`,
        "idempotency-key": `rev-create-${suffix}`,
      },
      payload: { albumId, body: "An incredible sonic journey." },
    });

    assert.equal(res.statusCode, 201);
    const body = JSON.parse(res.payload);
    assert.equal(body.albumId, albumId);
    assert.equal(body.body, "An incredible sonic journey.");
    assert.equal(body.revision, 0);
    reviewId = body.id;

    const dbReview = await app!.db.query("SELECT body FROM reviews WHERE id = $1", [reviewId]);
    assert.equal(dbReview.rows[0].body, "An incredible sonic journey.");
  });

  // Step 6: Update review
  await t.test("6. update review increments revision", async () => {
    const res = await app!.inject({
      method: "PUT",
      url: `/v1/reviews/${reviewId}`,
      headers: {
        authorization: `Bearer ${accessToken}`,
        "idempotency-key": `rev-update-${suffix}`,
      },
      payload: { body: "An incredible sonic journey. Updated thoughts.", expectedRevision: 0 },
    });

    assert.equal(res.statusCode, 200);
    const body = JSON.parse(res.payload);
    assert.equal(body.revision, 1);
    assert.equal(body.body, "An incredible sonic journey. Updated thoughts.");
  });

  // Step 7: Create list
  await t.test("7. create list", async () => {
    const res = await app!.inject({
      method: "POST",
      url: "/v1/lists",
      headers: {
        authorization: `Bearer ${accessToken}`,
        "idempotency-key": `list-create-${suffix}`,
      },
      payload: { title: "Best of 2024", note: "Top picks" },
    });

    assert.equal(res.statusCode, 201);
    const body = JSON.parse(res.payload);
    assert.equal(body.title, "Best of 2024");
    assert.equal(body.ownerId, userId);
    assert.deepEqual(body.items, []);
    listId = body.id;
  });

  // Step 8: Add item to list
  await t.test("8. add item to list verifies position", async () => {
    const res = await app!.inject({
      method: "POST",
      url: `/v1/lists/${listId}/items`,
      headers: {
        authorization: `Bearer ${accessToken}`,
        "idempotency-key": `list-item-${suffix}`,
      },
      payload: { albumId, note: "Must listen" },
    });

    assert.equal(res.statusCode, 201);
    const body = JSON.parse(res.payload);
    assert.equal(body.items.length, 1);
    assert.equal(body.items[0].albumId, albumId);
    assert.equal(body.items[0].position, 1);
  });

  // Step 9: Get feed
  await t.test("9. get feed shows activity events", async () => {
    // Invalidate feed cache first
    await app!.db.redis.del(`feed:${userId}:page1`);

    const res = await app!.inject({
      method: "GET",
      url: "/v1/feed",
      headers: { authorization: `Bearer ${accessToken}` },
    });

    assert.equal(res.statusCode, 200);
    const body = JSON.parse(res.payload);
    assert.ok(Array.isArray(body.items));
    assert.ok(body.items.length > 0);

    activityId = body.items[0].id;
  });

  // Step 10: React to activity
  await t.test("10. react to activity increments count", async () => {
    const res = await app!.inject({
      method: "POST",
      url: `/v1/activity/${activityId}/react`,
      headers: {
        authorization: `Bearer ${accessToken}`,
        "idempotency-key": `react-${suffix}`,
      },
      payload: { reaction: "fire" },
    });

    assert.equal(res.statusCode, 201);
    const body = JSON.parse(res.payload);
    assert.equal(body.activityId, activityId);
    assert.ok(body.reactions >= 1);
  });

  // Step 11: Get profile
  await t.test("11. profile stats are updated", async () => {
    // Bust cache to get fresh data
    await app!.db.redis.del(`profile:${userId}`);

    const res = await app!.inject({
      method: "GET",
      url: "/v1/me",
      headers: { authorization: `Bearer ${accessToken}` },
    });

    assert.equal(res.statusCode, 200);
    const body = JSON.parse(res.payload);
    assert.equal(body.id, userId);
    assert.ok(body.logCount >= 1);
    assert.ok(body.reviewCount >= 1);
    assert.ok(body.listCount >= 1);
  });

  // Step 12: Get weekly recap
  await t.test("12. weekly recap returns aggregation", async () => {
    const res = await app!.inject({
      method: "GET",
      url: "/v1/recaps/weekly/latest",
      headers: { authorization: `Bearer ${accessToken}` },
    });

    assert.equal(res.statusCode, 200);
    const body = JSON.parse(res.payload);
    assert.ok(body.weekStart);
    assert.ok(body.weekEnd);
    assert.ok(typeof body.totalLogs === "number");
  });

  // Step 13: Export data
  await t.test("13. export contains all user data", async () => {
    const res = await app!.inject({
      method: "POST",
      url: "/v1/account/export",
      headers: { authorization: `Bearer ${accessToken}` },
    });

    assert.equal(res.statusCode, 200);
    const body = JSON.parse(res.payload);
    assert.ok(body.generatedAt);
    assert.ok(body.profile);
    assert.equal(body.profile.id, userId);
    assert.ok(Array.isArray(body.ratings));
    assert.ok(body.ratings.length >= 1);
    assert.ok(Array.isArray(body.reviews));
    assert.ok(body.reviews.length >= 1);
    assert.ok(Array.isArray(body.lists));
    assert.ok(body.lists.length >= 1);
  });

  // Step 14: Delete account
  await t.test("14. delete account cascades all data", async () => {
    const res = await app!.inject({
      method: "DELETE",
      url: "/v1/account",
      headers: { authorization: `Bearer ${accessToken}` },
    });

    assert.equal(res.statusCode, 204);

    const user = await app!.db.query("SELECT id FROM users WHERE id = $1", [userId]);
    assert.equal(user.rowCount, 0);

    const ratings = await app!.db.query("SELECT id FROM ratings WHERE user_id = $1", [userId]);
    assert.equal(ratings.rowCount, 0);

    const reviews = await app!.db.query("SELECT id FROM reviews WHERE user_id = $1", [userId]);
    assert.equal(reviews.rowCount, 0);

    const lists = await app!.db.query("SELECT id FROM lists WHERE owner_id = $1", [userId]);
    assert.equal(lists.rowCount, 0);

    const sessions = await app!.db.query(
      "SELECT access_token FROM sessions WHERE user_id = $1",
      [userId],
    );
    assert.equal(sessions.rowCount, 0);
  });
});
