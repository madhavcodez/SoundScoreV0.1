import assert from "node:assert/strict";
import crypto from "node:crypto";
import test from "node:test";
import { SpotifyAdapter } from "../lib/spotify-adapter";
import { getAdapter, SUPPORTED_PROVIDERS } from "../lib/provider-registry";
import type { ProviderAdapter, TokenBundle } from "../lib/provider-adapter";

// ---------------------------------------------------------------------------
// Provider registry
// ---------------------------------------------------------------------------

test("getAdapter returns SpotifyAdapter for 'spotify'", () => {
  const adapter = getAdapter("spotify");
  assert.ok(adapter);
  assert.equal(adapter.name, "spotify");
});

test("getAdapter returns null for unsupported provider", () => {
  assert.equal(getAdapter("tidal"), null);
  assert.equal(getAdapter(""), null);
});

test("SUPPORTED_PROVIDERS includes spotify", () => {
  assert.ok(SUPPORTED_PROVIDERS.includes("spotify"));
});

// ---------------------------------------------------------------------------
// SpotifyAdapter — OAuth URL generation
// ---------------------------------------------------------------------------

test("SpotifyAdapter.getOAuthUrl builds correct URL with state and redirect", () => {
  const adapter = new SpotifyAdapter();
  const state = crypto.randomBytes(16).toString("hex");
  const redirectUri = "https://app.soundscore.io/callback";

  const url = adapter.getOAuthUrl(state, redirectUri);
  const parsed = new URL(url);

  assert.equal(parsed.origin, "https://accounts.spotify.com");
  assert.equal(parsed.pathname, "/authorize");
  assert.equal(parsed.searchParams.get("response_type"), "code");
  assert.equal(parsed.searchParams.get("state"), state);
  assert.equal(parsed.searchParams.get("redirect_uri"), redirectUri);
  assert.ok(parsed.searchParams.get("scope")?.includes("user-read-recently-played"));
  assert.ok(parsed.searchParams.get("scope")?.includes("user-read-email"));
  assert.ok(parsed.searchParams.get("scope")?.includes("user-library-read"));
});

test("SpotifyAdapter.getOAuthUrl accepts custom scopes", () => {
  const adapter = new SpotifyAdapter();
  const url = adapter.getOAuthUrl("state123", "https://example.com/cb", ["streaming"]);
  const parsed = new URL(url);

  assert.equal(parsed.searchParams.get("scope"), "streaming");
});

// ---------------------------------------------------------------------------
// OAuth state generation pattern
// ---------------------------------------------------------------------------

test("crypto.randomBytes generates unique state values", () => {
  const states = new Set<string>();
  for (let i = 0; i < 100; i++) {
    states.add(crypto.randomBytes(32).toString("hex"));
  }
  assert.equal(states.size, 100, "All 100 generated states should be unique");
});

test("state is 64 hex characters (32 bytes)", () => {
  const state = crypto.randomBytes(32).toString("hex");
  assert.equal(state.length, 64);
  assert.match(state, /^[0-9a-f]{64}$/);
});

// ---------------------------------------------------------------------------
// ProviderAdapter interface conformance
// ---------------------------------------------------------------------------

test("SpotifyAdapter implements ProviderAdapter interface", () => {
  const adapter: ProviderAdapter = new SpotifyAdapter();
  assert.equal(typeof adapter.name, "string");
  assert.equal(typeof adapter.getOAuthUrl, "function");
  assert.equal(typeof adapter.exchangeCode, "function");
  assert.equal(typeof adapter.refreshToken, "function");
  assert.equal(typeof adapter.revokeToken, "function");
});

test("SpotifyAdapter.revokeToken resolves without error", async () => {
  const adapter = new SpotifyAdapter();
  // Spotify revoke is a no-op, should resolve cleanly
  await adapter.revokeToken("any-token");
});

// ---------------------------------------------------------------------------
// Token expiry logic (unit tests for the comparison pattern used in token-refresh)
// ---------------------------------------------------------------------------

const REFRESH_BUFFER_MS = 5 * 60 * 1000;

test("token is considered fresh when expiry is >5 minutes away", () => {
  const expiresAt = new Date(Date.now() + 10 * 60 * 1000); // 10 min from now
  const needsRefresh = expiresAt.getTime() - Date.now() <= REFRESH_BUFFER_MS;
  assert.equal(needsRefresh, false);
});

test("token is considered stale when expiry is <5 minutes away", () => {
  const expiresAt = new Date(Date.now() + 2 * 60 * 1000); // 2 min from now
  const needsRefresh = expiresAt.getTime() - Date.now() <= REFRESH_BUFFER_MS;
  assert.equal(needsRefresh, true);
});

test("token is considered stale when already expired", () => {
  const expiresAt = new Date(Date.now() - 60 * 1000); // 1 min ago
  const needsRefresh = expiresAt.getTime() - Date.now() <= REFRESH_BUFFER_MS;
  assert.equal(needsRefresh, true);
});

// ---------------------------------------------------------------------------
// Provider validation pattern
// ---------------------------------------------------------------------------

test("provider validation rejects unknown providers", () => {
  const VALID = new Set(SUPPORTED_PROVIDERS);
  assert.equal(VALID.has("spotify"), true);
  assert.equal(VALID.has("apple_music" as typeof SUPPORTED_PROVIDERS[number]), false);
  assert.equal(VALID.has("tidal" as typeof SUPPORTED_PROVIDERS[number]), false);
});

// ---------------------------------------------------------------------------
// Token bundle shape
// ---------------------------------------------------------------------------

test("TokenBundle minimal shape (access_token only)", () => {
  const bundle: TokenBundle = { access_token: "tok_abc" };
  assert.equal(bundle.access_token, "tok_abc");
  assert.equal(bundle.refresh_token, undefined);
  assert.equal(bundle.expires_in, undefined);
  assert.equal(bundle.scope, undefined);
});

test("TokenBundle full shape", () => {
  const bundle: TokenBundle = {
    access_token: "tok_abc",
    refresh_token: "rtk_def",
    expires_in: 3600,
    scope: "user-read-recently-played user-read-email",
  };
  assert.equal(bundle.access_token, "tok_abc");
  assert.equal(bundle.refresh_token, "rtk_def");
  assert.equal(bundle.expires_in, 3600);
  assert.ok(bundle.scope?.includes("user-read-recently-played"));
});

// ---------------------------------------------------------------------------
// Scope parsing (mirrors callback handler logic)
// ---------------------------------------------------------------------------

test("scope string splits into array correctly", () => {
  const scope = "user-read-recently-played user-read-email user-library-read";
  const scopes = scope.split(" ");
  assert.deepEqual(scopes, [
    "user-read-recently-played",
    "user-read-email",
    "user-library-read",
  ]);
});

test("empty scope produces empty array", () => {
  const scope: string = "";
  const scopes = scope ? scope.split(" ") : [];
  assert.deepEqual(scopes, []);
});
