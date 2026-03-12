import assert from "node:assert/strict";
import test from "node:test";
import { mapUserProfile } from "../lib/mappers";

test("mapUserProfile maps snake_case columns to API shape", () => {
  const result = mapUserProfile({
    id: "usr_1",
    handle: "@madhav",
    bio: "bio",
    log_count: 12,
    review_count: 7,
    list_count: 4,
    avg_rating: 4.25,
  });

  assert.equal(result.id, "usr_1");
  assert.equal(result.handle, "@madhav");
  assert.equal(result.logCount, 12);
  assert.equal(result.reviewCount, 7);
  assert.equal(result.listCount, 4);
  assert.equal(result.avgRating, 4.25);
});
