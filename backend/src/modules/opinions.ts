import type { FastifyInstance } from "fastify";
import {
  CreateRatingRequestSchema,
  CreateReviewRequestSchema,
  UpdateReviewRequestSchema,
} from "@soundscore/contracts";
import type { InMemoryStore } from "../types";
import { conflict, notFound } from "../lib/errors";
import { nowIso, uid } from "../lib/util";
import { withIdempotency } from "../lib/idempotency";

export const registerOpinionRoutes = (app: FastifyInstance, store: InMemoryStore) => {
  app.get("/v1/log/recently-played", async (request) => {
    const userId = app.requireAuth(request);
    const recentlyPlayed = store.listeningEvents
      .filter((event) => event.userId === userId)
      .sort((a, b) => b.playedAt.localeCompare(a.playedAt))
      .slice(0, 30);

    return {
      items: recentlyPlayed,
      nextCursor: null,
    };
  });

  app.post("/v1/ratings", async (request, reply) => {
    const userId = app.requireAuth(request);
    const payload = CreateRatingRequestSchema.parse(request.body);
    if (!store.albums.has(payload.albumId)) {
      throw notFound("Album");
    }

    return withIdempotency(request, reply, store, userId, async () => {
      const existing = [...store.ratings.values()].find((rating) => rating.userId === userId && rating.albumId === payload.albumId);
      const now = nowIso();
      const rating = existing
        ? { ...existing, value: payload.value, updatedAt: now }
        : {
            id: uid("rat"),
            userId,
            albumId: payload.albumId,
            value: payload.value,
            createdAt: now,
            updatedAt: now,
          };

      store.ratings.set(rating.id, rating);
      const user = store.users.get(userId);
      if (user) {
        const userRatings = [...store.ratings.values()].filter((candidate) => candidate.userId === userId);
        const avgRating = userRatings.length
          ? userRatings.reduce((sum, candidate) => sum + candidate.value, 0) / userRatings.length
          : 0;
        user.profile = {
          ...user.profile,
          logCount: userRatings.length,
          avgRating: Number(avgRating.toFixed(2)),
        };
      }

      store.listeningEvents.push({
        id: uid("lst"),
        userId,
        albumId: payload.albumId,
        playedAt: now,
        source: "manual",
        sourceRef: {},
      });
      store.activity.unshift({
        id: uid("act"),
        actorId: userId,
        type: "RATED_ALBUM",
        object: { type: "album", id: payload.albumId },
        createdAt: now,
        payload: { albumId: payload.albumId, rating: payload.value },
        reactions: 0,
        comments: 0,
      });

      return rating;
    });
  });

  app.post("/v1/reviews", async (request, reply) => {
    const userId = app.requireAuth(request);
    const payload = CreateReviewRequestSchema.parse(request.body);
    if (!store.albums.has(payload.albumId)) {
      throw notFound("Album");
    }

    return withIdempotency(request, reply, store, userId, async () => {
      const now = nowIso();
      const review = {
        id: uid("rev"),
        userId,
        albumId: payload.albumId,
        body: payload.body,
        revision: 0,
        createdAt: now,
        updatedAt: now,
      };

      store.reviews.set(review.id, review);
      const user = store.users.get(userId);
      if (user) {
        const reviewCount = [...store.reviews.values()].filter((candidate) => candidate.userId === userId).length;
        user.profile = {
          ...user.profile,
          reviewCount,
        };
      }
      store.activity.unshift({
        id: uid("act"),
        actorId: userId,
        type: "WROTE_REVIEW",
        object: { type: "review", id: review.id },
        createdAt: now,
        payload: { albumId: payload.albumId, reviewId: review.id },
        reactions: 0,
        comments: 0,
      });

      return review;
    });
  });

  app.put("/v1/reviews/:id", async (request, reply) => {
    const userId = app.requireAuth(request);
    const reviewId = (request.params as { id: string }).id;
    const payload = UpdateReviewRequestSchema.parse(request.body);

    return withIdempotency(request, reply, store, userId, async () => {
      const review = store.reviews.get(reviewId);
      if (!review || review.userId !== userId) {
        throw notFound("Review");
      }
      if (review.revision !== payload.expectedRevision) {
        throw conflict("REVIEW_REVISION_CONFLICT", "Review has been updated on another device");
      }

      const updated = {
        ...review,
        body: payload.body,
        revision: review.revision + 1,
        updatedAt: nowIso(),
      };
      store.reviews.set(updated.id, updated);
      return updated;
    });
  });
};
