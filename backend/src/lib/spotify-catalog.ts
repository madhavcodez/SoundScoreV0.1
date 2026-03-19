import { env } from "../config/env";
import type { Db } from "../db/client";

const SPOTIFY_TOKEN_URL = "https://accounts.spotify.com/api/token";
const SPOTIFY_SEARCH_URL = "https://api.spotify.com/v1/search";

let cachedToken: string | null = null;
let tokenExpiry = 0;

interface SpotifyAlbumData {
  spotifyId: string;
  title: string;
  artist: string;
  year: number;
  artworkUrl: string;
  genres: string[];
  popularity: number;
  label: string | null;
  totalTracks: number;
}

async function ensureClientToken(): Promise<string> {
  if (cachedToken && Date.now() < tokenExpiry) return cachedToken;

  const credentials = Buffer.from(
    `${env.spotify.clientId}:${env.spotify.clientSecret}`,
  ).toString("base64");

  const response = await fetch(SPOTIFY_TOKEN_URL, {
    method: "POST",
    headers: {
      Authorization: `Basic ${credentials}`,
      "Content-Type": "application/x-www-form-urlencoded",
    },
    body: "grant_type=client_credentials",
  });

  if (!response.ok) {
    throw new Error(`Spotify client credentials failed: ${response.status}`);
  }

  const data = (await response.json()) as {
    access_token: string;
    expires_in: number;
  };
  cachedToken = data.access_token;
  tokenExpiry = Date.now() + (data.expires_in - 60) * 1000;
  return data.access_token;
}

export async function searchSpotify(
  query: string,
  limit = 5,
): Promise<SpotifyAlbumData[]> {
  const token = await ensureClientToken();

  const params = new URLSearchParams({
    q: query,
    type: "album",
    limit: String(Math.min(limit, 10)),
  });

  const response = await fetch(`${SPOTIFY_SEARCH_URL}?${params}`, {
    headers: { Authorization: `Bearer ${token}` },
  });

  if (!response.ok) return [];

  const data = (await response.json()) as {
    albums: {
      items: Array<{
        id: string;
        name: string;
        artists: Array<{ name: string }>;
        images: Array<{ url: string }>;
        release_date: string;
        genres?: string[];
        popularity?: number;
        label?: string;
        total_tracks?: number;
      }>;
    };
  };

  return data.albums.items
    .filter((a) => a.images.length > 0)
    .map((album) => ({
      spotifyId: album.id,
      title: album.name,
      artist: album.artists[0]?.name ?? "Unknown",
      year: parseInt(album.release_date.substring(0, 4)) || 0,
      artworkUrl: album.images[0].url,
      genres: album.genres ?? [],
      popularity: album.popularity ?? 0,
      label: album.label ?? null,
      totalTracks: album.total_tracks ?? 0,
    }));
}

export async function upsertAlbumFromSpotify(
  db: Db,
  album: SpotifyAlbumData,
): Promise<string> {
  // Check if album already exists by spotify_id
  const existing = await db.query<{ id: string }>(
    "SELECT id FROM albums WHERE spotify_id = $1",
    [album.spotifyId],
  );

  if (existing.rowCount && existing.rowCount > 0) {
    return existing.rows[0].id;
  }

  const albumId = `alb_${album.spotifyId.substring(0, 12)}`;

  await db.query(
    `INSERT INTO albums (id, title, artist, year, artwork_url, spotify_id, genres, popularity, label, total_tracks, avg_rating, log_count, created_at, updated_at)
     VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, 0, 0, NOW(), NOW())
     ON CONFLICT (spotify_id) DO UPDATE
     SET title = EXCLUDED.title, artist = EXCLUDED.artist, artwork_url = EXCLUDED.artwork_url,
         genres = EXCLUDED.genres, popularity = EXCLUDED.popularity, label = EXCLUDED.label,
         total_tracks = EXCLUDED.total_tracks, updated_at = NOW()`,
    [
      albumId,
      album.title,
      album.artist,
      album.year,
      album.artworkUrl,
      album.spotifyId,
      album.genres,
      album.popularity,
      album.label,
      album.totalTracks,
    ],
  );

  // Insert into genre junction table
  for (const genre of album.genres) {
    await db.query(
      `INSERT INTO album_genres (album_id, genre) VALUES ($1, $2) ON CONFLICT DO NOTHING`,
      [albumId, genre],
    );
  }

  return albumId;
}
