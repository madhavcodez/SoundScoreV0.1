import type { FastifyInstance } from "fastify";
import type { Db } from "../db/client";
import { notFound } from "../lib/errors";
import { parsePaginationParams, buildPaginatedResponse } from "../lib/pagination";

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

    const mapped = albums.rows.map((album) => ({
      id: album.id,
      title: album.title,
      artist: album.artist,
      year: album.year,
      artworkUrl: album.artwork_url,
      avgRating: Number(album.avg_rating),
      logCount: album.log_count,
    }));

    return buildPaginatedResponse(mapped, limit, (item) => String(item.logCount));
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
