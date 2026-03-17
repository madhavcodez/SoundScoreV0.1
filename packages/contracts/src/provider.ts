import { z } from "zod";

/** Supported music provider names. */
export const ProviderName = z.enum(["spotify", "apple_music", "musicbrainz"]);
export type ProviderName = z.infer<typeof ProviderName>;

/** Typed error codes for provider-related failures. */
export const ProviderErrorCode = z.enum([
  "PROVIDER_NOT_SUPPORTED",
  "OAUTH_STATE_MISMATCH",
  "OAUTH_EXCHANGE_FAILED",
  "TOKEN_EXPIRED",
  "TOKEN_REFRESH_FAILED",
  "ALREADY_CONNECTED",
  "NOT_CONNECTED",
  "RATE_LIMITED",
]);
export type ProviderErrorCode = z.infer<typeof ProviderErrorCode>;

/** Request to initiate an OAuth connect flow with a provider. */
export const ConnectProviderRequestSchema = z.object({
  provider: ProviderName,
  redirectUri: z.string().url(),
});

/** OAuth callback payload returned by the provider redirect. */
export const OAuthCallbackRequestSchema = z.object({
  provider: ProviderName,
  code: z.string(),
  state: z.string(),
});

/** Persistent record of a user's connection to an external provider. */
export const ProviderConnectionSchema = z.object({
  id: z.string(),
  userId: z.string(),
  provider: ProviderName,
  connected: z.boolean(),
  connectedAt: z.string().datetime(),
  scopes: z.array(z.string()),
  tokenExpiresAt: z.string().datetime().optional(),
});

/** Response containing the current provider connection status. */
export const ProviderStatusResponseSchema = z.object({
  connection: ProviderConnectionSchema.nullable(),
});

/** Request to disconnect a provider and optionally purge imported data. */
export const DisconnectProviderRequestSchema = z.object({
  provider: ProviderName,
  purgeData: z.boolean().default(false),
});

export type ConnectProviderRequest = z.infer<typeof ConnectProviderRequestSchema>;
export type OAuthCallbackRequest = z.infer<typeof OAuthCallbackRequestSchema>;
export type ProviderConnection = z.infer<typeof ProviderConnectionSchema>;
export type ProviderStatusResponse = z.infer<typeof ProviderStatusResponseSchema>;
export type DisconnectProviderRequest = z.infer<typeof DisconnectProviderRequestSchema>;
