import type { FastifyInstance } from "fastify";
import type { Db } from "../db/client";
import { badRequest, notFound } from "../lib/errors";
import { normalizeText } from "../lib/normalize";
import { uid } from "../lib/util";

type MappingMetadata = {
  title: string;
  artist: string;
  year?: number;
  trackCount?: number;
  artworkUrl?: string;
};

type CanonicalAlbum = {
  id: string;
  title: string;
  artistId: string;
  artistName: string;
  year: number | null;
  trackCount: number | null;
  artworkUrl: string | null;
};

type MappingRecord = {
  id: string;
  canonicalId: string;
  provider: string;
  providerId: string;
  confidence: number;
  status: string;
};

export type ResolveResult = {
  canonicalAlbum: CanonicalAlbum;
  mapping: MappingRecord;
  isNew: boolean;
};

const findOrCreateArtist = async (
  db: Db,
  artistName: string,
): Promise<{ id: string; name: string; normalizedName: string }> => {
  const normalized = normalizeText(artistName);

  const existing = await db.query<{ id: string; name: string; normalized_name: string }>(
    "SELECT id, name, normalized_name FROM canonical_artists WHERE normalized_name = $1 LIMIT 1",
    [normalized],
  );

  if (existing.rowCount) {
    const row = existing.rows[0];
    return { id: row.id, name: row.name, normalizedName: row.normalized_name };
  }

  const id = uid("cna");
  await db.query(
    "INSERT INTO canonical_artists (id, name, normalized_name) VALUES ($1, $2, $3)",
    [id, artistName, normalized],
  );
  return { id, name: artistName, normalizedName: normalized };
};

export const scoreMatch = (
  normalizedTitle: string,
  normalizedArtist: string,
  candidate: {
    normalized_title: string;
    artist_normalized_name: string;
    year: number | null;
    track_count: number | null;
  },
  metadata: MappingMetadata,
): number => {
  let score = 0;
  if (candidate.normalized_title === normalizedTitle) score += 0.5;
  if (candidate.artist_normalized_name === normalizedArtist) score += 0.3;
  if (
    metadata.year != null &&
    candidate.year != null &&
    Math.abs(metadata.year - candidate.year) <= 1
  ) {
    score += 0.1;
  }
  if (
    metadata.trackCount != null &&
    candidate.track_count != null &&
    metadata.trackCount === candidate.track_count
  ) {
    score += 0.1;
  }
  return score;
};

const upsertMapping = async (
  db: Db,
  canonicalId: string,
  provider: string,
  providerId: string,
  confidence: number,
  status: "confirmed" | "pending",
): Promise<string> => {
  const mappingId = uid("pmp");
  const result = await db.query<{ id: string }>(
    `INSERT INTO provider_mappings (id, canonical_id, canonical_type, provider, provider_id, confidence, provenance, status)
     VALUES ($1, $2, 'album', $3, $4, $5, 'auto_match', $6)
     ON CONFLICT (provider, provider_id)
     DO UPDATE SET canonical_id = $2, confidence = $5, status = $6, updated_at = NOW()
     RETURNING id`,
    [mappingId, canonicalId, provider, providerId, confidence, status],
  );
  return result.rows[0].id;
};

const loadCanonicalAlbumWithArtist = async (
  db: Db,
  albumId: string,
): Promise<CanonicalAlbum | null> => {
  const album = await db.query<{
    id: string;
    title: string;
    artist_id: string;
    year: number | null;
    track_count: number | null;
    artwork_url: string | null;
  }>(
    "SELECT id, title, artist_id, year, track_count, artwork_url FROM canonical_albums WHERE id = $1",
    [albumId],
  );

  if (!album.rowCount) return null;

  const row = album.rows[0];
  const artist = await db.query<{ name: string }>(
    "SELECT name FROM canonical_artists WHERE id = $1",
    [row.artist_id],
  );

  return {
    id: row.id,
    title: row.title,
    artistId: row.artist_id,
    artistName: artist.rows[0]?.name ?? "",
    year: row.year,
    trackCount: row.track_count,
    artworkUrl: row.artwork_url,
  };
};

export const resolveMapping = async (
  db: Db,
  provider: string,
  providerId: string,
  metadata: MappingMetadata,
): Promise<ResolveResult> => {
  // 1. Check existing confirmed mapping
  const existingMapping = await db.query<{
    id: string;
    canonical_id: string;
    confidence: number;
    status: string;
  }>(
    "SELECT id, canonical_id, confidence, status FROM provider_mappings WHERE provider = $1 AND provider_id = $2",
    [provider, providerId],
  );

  if (existingMapping.rowCount && existingMapping.rows[0].status === "confirmed") {
    const mapping = existingMapping.rows[0];
    const canonicalAlbum = await loadCanonicalAlbumWithArtist(db, mapping.canonical_id);

    if (canonicalAlbum) {
      return {
        canonicalAlbum,
        mapping: {
          id: mapping.id,
          canonicalId: mapping.canonical_id,
          provider,
          providerId,
          confidence: mapping.confidence,
          status: mapping.status,
        },
        isNew: false,
      };
    }
  }

  // 2. Normalize title and artist
  const normalizedTitle = normalizeText(metadata.title);
  const normalizedArtist = normalizeText(metadata.artist);

  // 3. Search canonical_albums for matches
  const candidates = await db.query<{
    id: string;
    title: string;
    normalized_title: string;
    artist_id: string;
    artist_name: string;
    artist_normalized_name: string;
    year: number | null;
    track_count: number | null;
    artwork_url: string | null;
  }>(
    `SELECT ca.id, ca.title, ca.normalized_title, ca.artist_id,
            cart.name AS artist_name, cart.normalized_name AS artist_normalized_name,
            ca.year, ca.track_count, ca.artwork_url
     FROM canonical_albums ca
     JOIN canonical_artists cart ON cart.id = ca.artist_id
     WHERE ca.normalized_title = $1 AND cart.normalized_name = $2`,
    [normalizedTitle, normalizedArtist],
  );

  // 4. Score candidates and find best match
  let bestMatch: (typeof candidates.rows)[number] | null = null;
  let bestScore = 0;

  for (const candidate of candidates.rows) {
    const score = scoreMatch(normalizedTitle, normalizedArtist, candidate, metadata);
    if (score > bestScore) {
      bestScore = score;
      bestMatch = candidate;
    }
  }

  // 5. High confidence (>= 0.7): confirmed mapping
  if (bestMatch && bestScore >= 0.7) {
    const mappingId = await upsertMapping(db, bestMatch.id, provider, providerId, bestScore, "confirmed");
    return {
      canonicalAlbum: {
        id: bestMatch.id,
        title: bestMatch.title,
        artistId: bestMatch.artist_id,
        artistName: bestMatch.artist_name,
        year: bestMatch.year,
        trackCount: bestMatch.track_count,
        artworkUrl: bestMatch.artwork_url,
      },
      mapping: {
        id: mappingId,
        canonicalId: bestMatch.id,
        provider,
        providerId,
        confidence: bestScore,
        status: "confirmed",
      },
      isNew: false,
    };
  }

  // 6. Medium confidence (0.4–0.7): pending mapping
  if (bestMatch && bestScore >= 0.4) {
    const mappingId = await upsertMapping(db, bestMatch.id, provider, providerId, bestScore, "pending");
    return {
      canonicalAlbum: {
        id: bestMatch.id,
        title: bestMatch.title,
        artistId: bestMatch.artist_id,
        artistName: bestMatch.artist_name,
        year: bestMatch.year,
        trackCount: bestMatch.track_count,
        artworkUrl: bestMatch.artwork_url,
      },
      mapping: {
        id: mappingId,
        canonicalId: bestMatch.id,
        provider,
        providerId,
        confidence: bestScore,
        status: "pending",
      },
      isNew: false,
    };
  }

  // 7. No match or low confidence: create new canonical album + artist, confirmed self-mapping
  const artist = await findOrCreateArtist(db, metadata.artist);
  const albumId = uid("cnb");

  await db.query(
    `INSERT INTO canonical_albums (id, title, normalized_title, artist_id, year, track_count, artwork_url)
     VALUES ($1, $2, $3, $4, $5, $6, $7)`,
    [
      albumId,
      metadata.title,
      normalizedTitle,
      artist.id,
      metadata.year ?? null,
      metadata.trackCount ?? null,
      metadata.artworkUrl ?? null,
    ],
  );

  // Also ensure album exists in the albums table for FK compatibility with listening_events
  await db.query(
    `INSERT INTO albums (id, title, artist, year, artwork_url, avg_rating, log_count)
     VALUES ($1, $2, $3, $4, $5, 0, 0)
     ON CONFLICT (id) DO NOTHING`,
    [albumId, metadata.title, metadata.artist, metadata.year ?? 0, metadata.artworkUrl ?? null],
  );

  const mappingId = await upsertMapping(db, albumId, provider, providerId, 1.0, "confirmed");

  return {
    canonicalAlbum: {
      id: albumId,
      title: metadata.title,
      artistId: artist.id,
      artistName: artist.name,
      year: metadata.year ?? null,
      trackCount: metadata.trackCount ?? null,
      artworkUrl: metadata.artworkUrl ?? null,
    },
    mapping: {
      id: mappingId,
      canonicalId: albumId,
      provider,
      providerId,
      confidence: 1.0,
      status: "confirmed",
    },
    isNew: true,
  };
};

export const registerMappingRoutes = (app: FastifyInstance, db: Db) => {
  // GET /v1/mappings/lookup?provider=spotify&provider_id=xxx
  app.get("/v1/mappings/lookup", async (request) => {
    const { provider, provider_id } = request.query as {
      provider?: string;
      provider_id?: string;
    };

    if (!provider || !provider_id) {
      throw badRequest("MISSING_PARAMS", "provider and provider_id are required");
    }

    const mapping = await db.query<{
      id: string;
      canonical_id: string;
      canonical_type: string;
      confidence: number;
      provenance: string;
      status: string;
    }>(
      `SELECT id, canonical_id, canonical_type, confidence, provenance, status
       FROM provider_mappings WHERE provider = $1 AND provider_id = $2`,
      [provider, provider_id],
    );

    if (!mapping.rowCount) {
      throw notFound("Mapping");
    }

    const canonicalId = mapping.rows[0].canonical_id;

    const allMappings = await db.query<{
      id: string;
      provider: string;
      provider_id: string;
      confidence: number;
      provenance: string;
      status: string;
    }>(
      `SELECT id, provider, provider_id, confidence, provenance, status
       FROM provider_mappings WHERE canonical_id = $1`,
      [canonicalId],
    );

    const canonicalAlbum = await loadCanonicalAlbumWithArtist(db, canonicalId);

    return {
      canonical: canonicalAlbum
        ? {
            id: canonicalAlbum.id,
            title: canonicalAlbum.title,
            artistId: canonicalAlbum.artistId,
            artistName: canonicalAlbum.artistName,
            year: canonicalAlbum.year,
            trackCount: canonicalAlbum.trackCount,
            artworkUrl: canonicalAlbum.artworkUrl,
          }
        : null,
      mappings: allMappings.rows.map((m) => ({
        id: m.id,
        provider: m.provider,
        providerId: m.provider_id,
        confidence: m.confidence,
        provenance: m.provenance,
        status: m.status,
      })),
    };
  });

  // POST /v1/mappings/resolve
  app.post("/v1/mappings/resolve", async (request) => {
    const body = request.body as {
      provider?: string;
      provider_id?: string;
      title?: string;
      artist?: string;
      year?: number;
      track_count?: number;
    };

    if (!body.provider || !body.provider_id || !body.title || !body.artist) {
      throw badRequest(
        "MISSING_PARAMS",
        "provider, provider_id, title, and artist are required",
      );
    }

    const result = await resolveMapping(db, body.provider, body.provider_id, {
      title: body.title,
      artist: body.artist,
      year: body.year,
      trackCount: body.track_count,
    });

    return {
      canonicalAlbum: result.canonicalAlbum,
      mapping: result.mapping,
      isNew: result.isNew,
    };
  });
};
