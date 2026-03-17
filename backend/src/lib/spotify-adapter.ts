import { env } from "../config/env";
import type { ProviderAdapter, TokenBundle } from "./provider-adapter";

const SPOTIFY_AUTHORIZE_URL = "https://accounts.spotify.com/authorize";
const SPOTIFY_TOKEN_URL = "https://accounts.spotify.com/api/token";

const DEFAULT_SCOPES = [
  "user-read-recently-played",
  "user-read-email",
  "user-library-read",
];

export class SpotifyAdapter implements ProviderAdapter {
  readonly name = "spotify";

  getOAuthUrl(state: string, redirectUri: string, scopes?: string[]): string {
    const params = new URLSearchParams({
      client_id: env.spotify.clientId,
      response_type: "code",
      redirect_uri: redirectUri,
      state,
      scope: (scopes ?? DEFAULT_SCOPES).join(" "),
    });
    return `${SPOTIFY_AUTHORIZE_URL}?${params.toString()}`;
  }

  async exchangeCode(code: string, redirectUri: string): Promise<TokenBundle> {
    const body = new URLSearchParams({
      grant_type: "authorization_code",
      code,
      redirect_uri: redirectUri,
    });

    const response = await fetch(SPOTIFY_TOKEN_URL, {
      method: "POST",
      headers: {
        "Content-Type": "application/x-www-form-urlencoded",
        Authorization: `Basic ${Buffer.from(`${env.spotify.clientId}:${env.spotify.clientSecret}`).toString("base64")}`,
      },
      body: body.toString(),
    });

    if (!response.ok) {
      const text = await response.text();
      throw new Error(`Spotify token exchange failed (${response.status}): ${text}`);
    }

    const data = (await response.json()) as TokenBundle;
    return {
      access_token: data.access_token,
      refresh_token: data.refresh_token,
      expires_in: data.expires_in,
      scope: data.scope,
    };
  }

  async refreshToken(refreshToken: string): Promise<TokenBundle> {
    const body = new URLSearchParams({
      grant_type: "refresh_token",
      refresh_token: refreshToken,
    });

    const response = await fetch(SPOTIFY_TOKEN_URL, {
      method: "POST",
      headers: {
        "Content-Type": "application/x-www-form-urlencoded",
        Authorization: `Basic ${Buffer.from(`${env.spotify.clientId}:${env.spotify.clientSecret}`).toString("base64")}`,
      },
      body: body.toString(),
    });

    if (!response.ok) {
      const text = await response.text();
      throw new Error(`Spotify token refresh failed (${response.status}): ${text}`);
    }

    const data = (await response.json()) as TokenBundle;
    return {
      access_token: data.access_token,
      refresh_token: data.refresh_token ?? refreshToken,
      expires_in: data.expires_in,
      scope: data.scope,
    };
  }

  async revokeToken(_accessToken: string): Promise<void> {
    // Spotify does not support token revocation via API.
    // Connection cleanup is handled by disconnecting on our side.
  }
}
