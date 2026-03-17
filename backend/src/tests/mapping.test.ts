import assert from "node:assert/strict";
import { describe, it } from "node:test";
import { normalizeText } from "../lib/normalize";
import { scoreMatch } from "../modules/mapping";

describe("normalizeText", () => {
  it("lowercases input", () => {
    assert.equal(normalizeText("HELLO World"), "hello world");
  });

  it("strips accents / diacritics", () => {
    assert.equal(normalizeText("Beyoncé"), "beyonce");
    assert.equal(normalizeText("Café Résumé"), "cafe resume");
  });

  it("removes special characters", () => {
    assert.equal(normalizeText("Rock & Roll!"), "rock roll");
    assert.equal(normalizeText("AC/DC — Highway"), "acdc highway");
  });

  it("collapses whitespace and trims", () => {
    assert.equal(normalizeText("  lots   of   space  "), "lots of space");
  });

  it("handles empty string", () => {
    assert.equal(normalizeText(""), "");
  });

  it("handles mixed accents and special chars", () => {
    assert.equal(normalizeText("Ñoño's Café!"), "nonos cafe");
  });
});

describe("scoreMatch", () => {
  const makeCandidate = (overrides: Partial<{
    normalized_title: string;
    artist_normalized_name: string;
    year: number | null;
    track_count: number | null;
  }> = {}) => ({
    normalized_title: "chromakopia",
    artist_normalized_name: "tyler the creator",
    year: 2024 as number | null,
    track_count: 14 as number | null,
    ...overrides,
  });

  it("gives 1.0 for exact match on all fields", () => {
    const score = scoreMatch(
      "chromakopia",
      "tyler the creator",
      makeCandidate(),
      { title: "CHROMAKOPIA", artist: "Tyler, the Creator", year: 2024, trackCount: 14 },
    );
    assert.equal(score, 1.0);
  });

  it("gives 0.8 for title + artist match only", () => {
    const score = scoreMatch(
      "chromakopia",
      "tyler the creator",
      makeCandidate({ year: null, track_count: null }),
      { title: "CHROMAKOPIA", artist: "Tyler, the Creator" },
    );
    assert.equal(score, 0.8);
  });

  it("gives 0.9 for title + artist + year within ±1", () => {
    const score = scoreMatch(
      "chromakopia",
      "tyler the creator",
      makeCandidate({ year: 2023, track_count: null }),
      { title: "CHROMAKOPIA", artist: "Tyler, the Creator", year: 2024 },
    );
    assert.equal(score, 0.9);
  });

  it("gives 0.5 for title-only match", () => {
    const score = scoreMatch(
      "chromakopia",
      "tyler the creator",
      makeCandidate({ artist_normalized_name: "someone else" }),
      { title: "CHROMAKOPIA", artist: "Tyler, the Creator", year: 2024, trackCount: 14 },
    );
    // title 0.5, artist mismatch 0, year +0.1, track +0.1 = 0.7
    assert.equal(score, 0.7);
  });

  it("gives 0 when nothing matches", () => {
    const score = scoreMatch(
      "gnx",
      "kendrick lamar",
      makeCandidate(),
      { title: "GNX", artist: "Kendrick Lamar", year: 2020 },
    );
    assert.equal(score, 0);
  });

  it("handles null year and track_count gracefully", () => {
    const score = scoreMatch(
      "chromakopia",
      "tyler the creator",
      makeCandidate({ year: null, track_count: null }),
      { title: "CHROMAKOPIA", artist: "Tyler, the Creator", year: 2024, trackCount: 14 },
    );
    // title 0.5 + artist 0.3 = 0.8 (year and track can't match null)
    assert.equal(score, 0.8);
  });
});
