const test = require("node:test");
const assert = require("node:assert/strict");
const {
  mixDiscoveryExploration,
} = require("../dist/src/modules/profile-setup/discovery-exploration.js");
const people = Array.from({ length: 20 }, (_, rank) => ({
  id: `member-${rank}`,
  rank,
}));

test("four relevance cards precede exploration from the lower-ranked half", () => {
  const result = mixDiscoveryExploration(people, "viewer:2026-10-23");
  assert.deepEqual(result.slice(0, 4), people.slice(0, 4));
  assert.ok(result[4].rank >= 10);
  assert.equal(new Set(result.map((p) => p.id)).size, people.length);
  assert.deepEqual(
    [...result].sort((a, b) => a.rank - b.rank),
    people,
  );
  assert.deepEqual(
    people.map((p) => p.rank),
    Array.from({ length: 20 }, (_, i) => i),
  );
});
test("refreshes are deterministic and viewer/day seeds allow different exploration", () => {
  const ids = (seed) => mixDiscoveryExploration(people, seed).map((p) => p.id);
  assert.deepEqual(ids("viewer-a:day-1"), ids("viewer-a:day-1"));
  const choices = new Set(
    Array.from({ length: 20 }, (_, i) => ids(`viewer-${i}:day-1`)[4]),
  );
  assert.ok(choices.size > 1);
});
test("small pools are preserved and partial batches contain no missing cards", () => {
  for (let size = 0; size <= 20; size++) {
    const input = people.slice(0, size);
    const result = mixDiscoveryExploration(input, "seed");
    assert.equal(result.length, size);
    assert.equal(new Set(result.map((p) => p.id)).size, size);
    if (size <= 4) assert.deepEqual(result, input);
  }
});
