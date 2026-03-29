const assert = require("node:assert/strict");
const {describe, it} = require("node:test");

const functionsIndex = require("../index");

const {
  classifyModerationText,
  buildModerationReviewPayload,
} = functionsIndex.__testing;

describe("moderation classification helpers", () => {
  it("classifyModerationText flags high-risk report content", () => {
    const result = classifyModerationText(
        "User made violent threat",
        "They said they would use a weapon and extort coins.",
    );

    assert.equal(result.riskLevel, "high");
    assert.equal(result.needsManualReview, true);
    assert.ok(result.score >= 3);
    assert.ok(result.matchedTerms.includes("threat"));
  });

  it("classifyModerationText returns low risk for neutral content", () => {
    const result = classifyModerationText(
        "Audio quality issue",
        "Connection dropped twice in room.",
    );

    assert.equal(result.riskLevel, "low");
    assert.equal(result.needsManualReview, false);
    assert.equal(result.score, 0);
  });

  it("buildModerationReviewPayload creates moderationReview metadata", () => {
    const payload = buildModerationReviewPayload({
      reason: "Possible spam account",
      details: "Repeated bot-like invites every minute",
    });

    assert.equal(payload.moderationReview.riskLevel, "medium");
    assert.equal(payload.moderationReview.classifierVersion, "v1-baseline");
    assert.equal(typeof payload.moderationReview.classifiedAt, "string");
    assert.ok(Array.isArray(payload.moderationReview.matchedTerms));
  });
});
