import { z } from "zod";
import { ProviderName } from "./provider";

/** Types of canonical entities owned by SoundScore. */
export const CanonicalEntityType = z.enum(["artist", "album", "track"]);
export type CanonicalEntityType = z.infer<typeof CanonicalEntityType>;

/** Canonical artist entity — provider-independent. */
export const CanonicalArtistSchema = z.object({
  id: z.string(),
  name: z.string(),
  normalizedName: z.string(),
  createdAt: z.string().datetime(),
});

/** Canonical album (release) entity — provider-independent. */
export const CanonicalAlbumSchema = z.object({
  id: z.string(),
  title: z.string(),
  normalizedTitle: z.string(),
  artistId: z.string(),
  year: z.number().int().optional(),
  trackCount: z.number().int().positive().optional(),
  createdAt: z.string().datetime(),
});

/** Confidence level of a canonical-to-provider mapping. */
export const MappingStatus = z.enum(["confirmed", "pending", "ambiguous", "unmapped"]);
export type MappingStatus = z.infer<typeof MappingStatus>;

/** How a mapping was established. */
export const MappingProvenance = z.enum([
  "auto_match",
  "user_confirm",
  "admin_override",
  "provider_link",
]);
export type MappingProvenance = z.infer<typeof MappingProvenance>;

/** Link between a canonical entity and a provider-specific ID. */
export const ProviderMappingSchema = z.object({
  id: z.string(),
  canonicalId: z.string(),
  canonicalType: CanonicalEntityType,
  provider: ProviderName,
  providerId: z.string(),
  confidence: z.number().min(0).max(1),
  provenance: MappingProvenance,
  status: MappingStatus,
  createdAt: z.string().datetime(),
});

/** Look up the canonical entity for a given provider ID. */
export const MappingLookupRequestSchema = z.object({
  provider: ProviderName,
  providerId: z.string(),
});

/** Result of a mapping lookup — canonical entity plus all known mappings. */
export const MappingLookupResponseSchema = z.object({
  canonical: CanonicalAlbumSchema.nullable(),
  mappings: z.array(ProviderMappingSchema),
  status: MappingStatus,
});

/** Request to resolve a provider item to a canonical entity using metadata. */
export const ResolveMappingRequestSchema = z.object({
  provider: ProviderName,
  providerId: z.string(),
  title: z.string(),
  artist: z.string(),
  year: z.number().int().optional(),
  trackCount: z.number().int().positive().optional(),
});

export type CanonicalArtist = z.infer<typeof CanonicalArtistSchema>;
export type CanonicalAlbum = z.infer<typeof CanonicalAlbumSchema>;
export type ProviderMapping = z.infer<typeof ProviderMappingSchema>;
export type MappingLookupRequest = z.infer<typeof MappingLookupRequestSchema>;
export type MappingLookupResponse = z.infer<typeof MappingLookupResponseSchema>;
export type ResolveMappingRequest = z.infer<typeof ResolveMappingRequestSchema>;
