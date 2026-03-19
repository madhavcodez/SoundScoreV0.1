import type { Db } from "../db/client";

const MB_API_BASE = "https://musicbrainz.org/ws/2";
const COVER_ART_BASE = "https://coverartarchive.org";
const USER_AGENT = "SoundScore/1.0 (https://soundscore.app)";

// MusicBrainz rate limit: 1 req/sec
let lastRequestAt = 0;

interface MusicBrainzAlbumData {
  mbid: string;
  title: string;
  artist: string;
  year: number;
  artworkUrl: string | null;
}

async function throttledFetch(url: string): Promise<Response> {
  const now = Date.now();
  const elapsed = now - lastRequestAt;
  if (elapsed < 1100) {
    await new Promise((resolve) => setTimeout(resolve, 1100 - elapsed));
  }
  lastRequestAt = Date.now();

  return fetch(url, {
    headers: {
      "User-Agent": USER_AGENT,
      Accept: "application/json",
    },
  });
}

async function fetchCoverArt(mbid: string): Promise<string | null> {
  try {
    const response = await throttledFetch(
      `${COVER_ART_BASE}/release-group/${mbid}`,
    );
    if (!response.ok) return null;

    const data = (await response.json()) as {
      images?: Array<{
        front: boolean;
        thumbnails?: { 500?: string; 250?: string; large?: string };
        image?: string;
      }>;
    };

    const front = data.images?.find((img) => img.front);
    if (front) {
      return (
        front.thumbnails?.["500"] ??
        front.thumbnails?.large ??
        front.image ??
        null
      );
    }
    return data.images?.[0]?.image ?? null;
  } catch {
    return null;
  }
}

export async function searchMusicBrainz(
  query: string,
  limit = 5,
): Promise<MusicBrainzAlbumData[]> {
  const params = new URLSearchParams({
    query: `releasegroup:"${query}"`,
    fmt: "json",
    limit: String(Math.min(limit, 10)),
  });

  const response = await throttledFetch(
    `${MB_API_BASE}/release-group?${params}`,
  );

  if (!response.ok) return [];

  const data = (await response.json()) as {
    "release-groups"?: Array<{
      id: string;
      title: string;
      "artist-credit"?: Array<{ name: string }>;
      "first-release-date"?: string;
    }>;
  };

  const groups = data["release-groups"] ?? [];

  const results: MusicBrainzAlbumData[] = [];
  for (const rg of groups.slice(0, limit)) {
    const artworkUrl = await fetchCoverArt(rg.id);
    results.push({
      mbid: rg.id,
      title: rg.title,
      artist: rg["artist-credit"]?.[0]?.name ?? "Unknown",
      year: parseInt(rg["first-release-date"]?.substring(0, 4) ?? "0") || 0,
      artworkUrl,
    });
  }

  return results;
}

export async function upsertAlbumFromMusicBrainz(
  db: Db,
  album: MusicBrainzAlbumData,
): Promise<string> {
  // Check if album already exists by title + artist match
  const existing = await db.query<{ id: string }>(
    `SELECT id FROM albums
     WHERE LOWER(title) = LOWER($1) AND LOWER(artist) = LOWER($2)
     LIMIT 1`,
    [album.title, album.artist],
  );

  if (existing.rowCount && existing.rowCount > 0) {
    return existing.rows[0].id;
  }

  const albumId = `alb_mb_${album.mbid.substring(0, 10)}`;

  await db.query(
    `INSERT INTO albums (id, title, artist, year, artwork_url, avg_rating, log_count, created_at, updated_at)
     VALUES ($1, $2, $3, $4, $5, 0, 0, NOW(), NOW())
     ON CONFLICT (id) DO UPDATE
     SET artwork_url = COALESCE(EXCLUDED.artwork_url, albums.artwork_url),
         updated_at = NOW()`,
    [albumId, album.title, album.artist, album.year, album.artworkUrl],
  );

  return albumId;
}
