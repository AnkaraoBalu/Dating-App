const test = require("node:test");
const assert = require("node:assert/strict");
const { validateSync } = require("class-validator");
const {
  UpdateOnboardingDto,
} = require("../dist/src/modules/users/dto/update-onboarding.dto.js");
const { UsersService } = require("../dist/src/modules/users/users.service.js");

const fields = [
  [
    "vibeTypes",
    "vibeType",
    ["sunshine", "black_cat", "slow_burn", "golden_retriever"],
    3,
  ],
  [
    "idealFridays",
    "idealFriday",
    ["gaming", "club", "rooftop", "quiet_evening"],
    3,
  ],
  [
    "currentEras",
    "currentEra",
    ["career_mode", "personal_growth", "travel_era"],
    2,
  ],
];

for (const [field, legacy, values, limit] of fields) {
  test(`${field} validates its cap, options, duplicates, and explicit clearing`, () => {
    const errors = (value) =>
      validateSync(
        Object.assign(new UpdateOnboardingDto(), { [field]: value }),
      );
    assert.equal(errors(values.slice(0, limit)).length, 0);
    assert.equal(errors([]).length, 0);
    for (const invalid of [
      values,
      [values[0], values[0]],
      ["invalid"],
      values[0],
      null,
    ]) {
      assert.ok(errors(invalid).length > 0);
    }
  });

  test(`${field} persists all choices and supports legacy writes and clearing`, async () => {
    let saved;
    const api = new UsersService(
      {
        user: { findUnique: async () => ({ id: "member" }) },
        onboardingProfile: {
          upsert: async (args) => {
            saved = args;
            return args.update;
          },
        },
      },
      { getOrThrow: () => "test-placeholder" },
    );
    const selected = values.slice(0, limit);
    await api.updateOnboarding("member", { [field]: selected });
    assert.deepEqual(saved.update[field], selected);
    assert.equal(saved.update[legacy], selected[0]);
    assert.deepEqual(saved.create[field], selected);
    await api.updateOnboarding("member", { [legacy]: values[0] });
    assert.deepEqual(saved.update[field], [values[0]]);
    await api.updateOnboarding("member", { [field]: [], [legacy]: values[0] });
    assert.deepEqual(saved.update[field], []);
    assert.equal(saved.update[legacy], null);
    await api.updateOnboarding("member", { preferredDistanceKm: 40 });
    assert.equal(field in saved.update, false);
  });
}
