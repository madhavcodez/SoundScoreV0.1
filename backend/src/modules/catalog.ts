import type { FastifyInstance } from "fastify";
import type { Db } from "../db/client";
import { notFound } from "../lib/errors";

export const registerCatalogRoutes = (app: FastifyInstance, db: Db) => {
  app.get("/v1/search", async (request) => {
    const query = ((request.query as { q?: string }).q ?? "").trim().toLowerCase();

    const albums = query
      ? await db.query<{
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
            WHERE LOWER(title) LIKE $1 OR LOWER(artist) LIKE $1
            ORDER BY log_count DESC
            LIMIT 50
          `,
          [`%${query}%`],
        )
      : await db.query<{
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
            ORDER BY log_count DESC
            LIMIT 50
          `,
        );

    return {
      items: albums.rows.map((album) => ({
        id: album.id,
        title: album.title,
        artist: album.artist,
        year: album.year,
        artworkUrl: album.artwork_url,
        avgRating: Number(album.avg_rating),
        logCount: album.log_count,
      })),
      nextCursor: null,
    };
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
