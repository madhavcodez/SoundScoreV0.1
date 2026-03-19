import type { FastifyInstance } from "fastify";
import type { Db } from "../db/client";
import { notFound } from "../lib/errors";
import { parsePaginationParams, buildPaginatedResponse } from "../lib/pagination";
import { searchSpotify, upsertAlbumFromSpotify } from "../lib/spotify-catalog";
import { searchMusicBrainz, upsertAlbumFromMusicBrainz } from "../lib/musicbrainz-catalog";

export const registerCatalogRoutes = (app: FastifyInstance, db: Db) => {
  app.get("/v1/search", async (request) => {
    const query = ((request.query as { q?: string }).q ?? "").trim().toLowerCase();
    const { cursor, limit } = parsePaginationParams(request);

    const cursorClause = cursor ? "AND log_count < $2" : "";
    const limitParam = cursor ? "$3" : "$2";

    type AlbumRow = {
      id: string;
      title: string;
      artist: string;
      year: number;
      artwork_url: string | null;
      avg_rating: number;
      log_count: number;
    };

    let albums;
    if (query) {
      // Use full-text search if search_vector column exists, fallback to LIKE
      const baseParams: unknown[] = [query];
      const cursorParams = cursor ? [cursor] : [];
      const allParams = [...baseParams, ...cursorParams, limit + 1];

      const cursorFilter = cursor ? `AND log_count < $${baseParams.length + 1}` : "";
      const limitIdx = allParams.length;

      albums = await db.query<AlbumRow>(
        `
          SELECT id, title, artist, year, artwork_url, avg_rating, log_count
          FROM albums
          WHERE (
            search_vector @@ plainto_tsquery('english', $1)
            OR LOWER(title) LIKE '%' || $1 || '%'
            OR LOWER(artist) LIKE '%' || $1 || '%'
          )
          ${cursorFilter}
          ORDER BY log_count DESC
          LIMIT $${limitIdx}
        `,
        allParams,
      );
    } else {
      const params: unknown[] = cursor ? [cursor, limit + 1] : [limit + 1];
      const cursorFilter = cursor ? "WHERE log_count < $1" : "";
      const limitIdx = params.length;

      albums = await db.query<AlbumRow>(
        `
          SELECT id, title, artist, year, artwork_url, avg_rating, log_count
          FROM albums
          ${cursorFilter}
          ORDER BY log_count DESC
          LIMIT $${limitIdx}
        `,
        params,
      );
    }

    let mapped = albums.rows.map((album) => ({
      id: album.id,
      title: album.title,
      artist: album.artist,
      year: album.year,
      artworkUrl: album.artwork_url,
      avgRating: Number(album.avg_rating),
      logCount: album.log_count,
    }));

    // If local results are sparse and we have a query, supplement with Spotify
    if (query && mapped.length < limit) {
      try {
        const cacheKey = `spotify_search:${query}`;
        const cached = await db.redis.get(cacheKey);
        let spotifyResults;

        if (cached) {
          spotifyResults = JSON.parse(cached);
        } else {
          spotifyResults = await searchSpotify(query, limit);
          await db.redis.setex(cacheKey, 300, JSON.stringify(spotifyResults));
        }

        // Upsert Spotify results and merge
        const localIds = new Set(mapped.map((a) => a.id));
        for (const sr of spotifyResults) {
          const albumId = await upsertAlbumFromSpotify(db, sr);
          if (!localIds.has(albumId)) {
            mapped.push({
              id: albumId,
              title: sr.title,
              artist: sr.artist,
              year: sr.year,
              artworkUrl: sr.artworkUrl,
              avgRating: 0,
              logCount: 0,
            });
          }
        }
      } catch {
        // Spotify fallback is best-effort
      }
    }

    // If still sparse after Spotify, try MusicBrainz (free, no API key, CC0 data)
    if (query && mapped.length < limit) {
      try {
        const mbResults = await searchMusicBrainz(query, limit - mapped.length);
        const localIds = new Set(mapped.map((a) => a.id));
        const localTitles = new Set(mapped.map((a) => `${a.title.toLowerCase()}|${a.artist.toLowerCase()}`));

        for (const mb of mbResults) {
          const key = `${mb.title.toLowerCase()}|${mb.artist.toLowerCase()}`;
          if (localTitles.has(key)) continue;

          const albumId = await upsertAlbumFromMusicBrainz(db, mb);
          if (!localIds.has(albumId)) {
            mapped.push({
              id: albumId,
              title: mb.title,
              artist: mb.artist,
              year: mb.year,
              artworkUrl: mb.artworkUrl,
              avgRating: 0,
              logCount: 0,
            });
          }
        }
      } catch {
        // MusicBrainz fallback is best-effort
      }
    }

    return buildPaginatedResponse(mapped, limit, (item) => String(item.logCount));
  });

  // Persist a Spotify album into the local catalog
  app.post("/v1/albums/from-spotify", async (request, reply) => {
    const body = request.body as {
      spotifyId: string;
      title: string;
      artist: string;
      year: number;
      artworkUrl: string;
      genres?: string[];
      popularity?: number;
      label?: string;
      totalTracks?: number;
    };

    if (!body.spotifyId || !body.title || !body.artist) {
      return reply.status(400).send({ error: "Missing required fields" });
    }

    const albumId = await upsertAlbumFromSpotify(db, {
      spotifyId: body.spotifyId,
      title: body.title,
      artist: body.artist,
      year: body.year ?? 0,
      artworkUrl: body.artworkUrl ?? "",
      genres: body.genres ?? [],
      popularity: body.popularity ?? 0,
      label: body.label ?? null,
      totalTracks: body.totalTracks ?? 0,
    });

    const album = await db.query<{
      id: string;
      title: string;
      artist: string;
      year: number;
      artwork_url: string | null;
      avg_rating: number;
      log_count: number;
    }>("SELECT id, title, artist, year, artwork_url, avg_rating, log_count FROM albums WHERE id = $1", [albumId]);

    if (!album.rowCount) {
      throw notFound("Album");
    }

    return reply.status(201).send({
      id: album.rows[0].id,
      title: album.rows[0].title,
      artist: album.rows[0].artist,
      year: album.rows[0].year,
      artworkUrl: album.rows[0].artwork_url,
      avgRating: Number(album.rows[0].avg_rating),
      logCount: album.rows[0].log_count,
    });
  });

  app.get("/v1/albums/:id", async (request) => {
    const albumId = (request.params as { id: string }).id;
    const album = await db.query<{
      id: string;
      title: string;
      artist: string;
      year: number;
      artwork_url: string | null;
      avg_rating: number;
      log_count: number;
    }>(
      `
        SELECT id, title, artist, year, artwork_url, avg_rating, log_count
        FROM albums
        WHERE id = $1
      `,
      [albumId],
    );

    if (!album.rowCount) {
      throw notFound("Album");
    }

    return {
      id: album.rows[0].id,
      title: album.rows[0].title,
      artist: album.rows[0].artist,
      year: album.rows[0].year,
      artworkUrl: album.rows[0].artwork_url,
      avgRating: Number(album.rows[0].avg_rating),
      logCount: album.rows[0].log_count,
    };
  });
};
