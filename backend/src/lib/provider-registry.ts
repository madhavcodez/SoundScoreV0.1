import type { ProviderAdapter } from "./provider-adapter";
import { SpotifyAdapter } from "./spotify-adapter";

const adapters = new Map<string, ProviderAdapter>([
  ["spotify", new SpotifyAdapter()],
]);

export const getAdapter = (provider: string): ProviderAdapter | null =>
  adapters.get(provider) ?? null;

export const SUPPORTED_PROVIDERS = [...adapters.keys()] as const;
