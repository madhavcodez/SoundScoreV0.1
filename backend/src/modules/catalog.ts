import type { FastifyInstance } from "fastify";
import type { InMemoryStore } from "../types";
import { notFound } from "../lib/errors";

export const registerCatalogRoutes = (app: FastifyInstance, store: InMemoryStore) => {
  app.get("/v1/search", async (request) => {
    const query = ((request.query as { q?: string }).q ?? "").trim().toLowerCase();
    const all = [...store.albums.values()];
    const albums = query
      ? all.filter((album) => album.title.toLowerCase().includes(query) || album.artist.toLowerCase().includes(query))
      : all;

    return {
      items: albums.slice(0, 50),
      nextCursor: null,
    };
  });

  app.get("/v1/albums/:id", async (request) => {
    const albumId = (request.params as { id: string }).id;
    const album = store.albums.get(albumId);
    if (!album) {
      throw notFound("Album");
    }
    return album;
  });
};
