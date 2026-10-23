const test = require("node:test");
const assert = require("node:assert/strict");
const {
  discoveryTrendingScore,
} = require("../dist/src/modules/profile-setup/discovery-trending.js");
const now = new Date("2026-10-23T12:00:00Z");
const old = new Date("2026-09-01");
const score = (changes = {}) =>
  discoveryTrendingScore({
    recentLikes: 0,
    lastActiveAt: null,
    createdAt: old,
    now,
    ...changes,
  });
test("Trending rewards recent engagement, activity and new profiles", () => {
  assert.ok(score({ recentLikes: 5 }) > score());
  assert.ok(score({ lastActiveAt: now }) > score({ lastActiveAt: old }));
  assert.ok(score({ createdAt: now }) > score());
  assert.equal(score(), 0);
});
test("popularity is capped and a new active member can outrank an inactive popular one", () => {
  assert.equal(score({ recentLikes: 20 }), score({ recentLikes: 10000 }));
  assert.ok(
    score({ recentLikes: 1, lastActiveAt: now, createdAt: now }) >
      score({ recentLikes: 10000 }),
  );
  assert.equal(
    score({ recentLikes: 20, lastActiveAt: now, createdAt: now }),
    100,
  );
});
