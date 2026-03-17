export interface TokenBundle {
  access_token: string;
  refresh_token?: string;
  expires_in?: number;
  scope?: string;
}

export interface ProviderAdapter {
  readonly name: string;
  getOAuthUrl(state: string, redirectUri: string, scopes?: string[]): string;
  exchangeCode(code: string, redirectUri: string): Promise<TokenBundle>;
  refreshToken(refreshToken: string): Promise<TokenBundle>;
  revokeToken(accessToken: string): Promise<void>;
}
