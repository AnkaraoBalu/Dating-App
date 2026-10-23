const test = require("node:test");
const assert = require("node:assert/strict");
const {
  discoveryInterestWeights,
  sharedInterestScore,
} = require("../dist/src/modules/profile-setup/discovery-affinity.js");
const weights = (changes = {}) =>
  discoveryInterestWeights({
    interests: [],
    musicGenres: [],
    favoriteArtists: [],
    ...changes,
  });

test("shared activities rank above shared artists and genres", () => {
  const current = weights({
    interests: ["coffee"],
    favoriteArtists: ["Adele"],
    musicGenres: ["pop"],
  });
  const activity = sharedInterestScore(
    current,
    weights({ interests: ["coffee"] }),
  );
  const artist = sharedInterestScore(
    current,
    weights({ favoriteArtists: ["Adele"] }),
  );
  const genre = sharedInterestScore(current, weights({ musicGenres: ["pop"] }));
  assert.ok(activity > artist && artist > genre);
});
test("duplicates and casing cannot inflate overlap", () => {
  const a = weights({
    interests: ["Coffee", "coffee", "COFFEE", "!!!"],
    favoriteArtists: ["Ａｄｅｌｅ"],
  });
  const b = weights({ interests: ["coffee"], favoriteArtists: ["adele"] });
  assert.equal(sharedInterestScore(a, b), 100);
  assert.equal(sharedInterestScore(b, a), 100);
});
test("score is symmetric and unmatched interests reduce overlap", () => {
  const a = weights({ interests: ["coffee"] });
  const b = weights({ interests: ["coffee", "travel"] });
  assert.equal(sharedInterestScore(a, b), 50);
  assert.equal(sharedInterestScore(b, a), 50);
  assert.equal(sharedInterestScore(weights(), weights()), 0);
  assert.equal(sharedInterestScore(a, weights()), 0);
});
test("categories stay distinct and Unicode names are preserved", () => {
  assert.equal(
    sharedInterestScore(
      weights({ interests: ["pop"] }),
      weights({ musicGenres: ["pop"] }),
    ),
    0,
  );
  assert.equal(
    sharedInterestScore(
      weights({ favoriteArtists: ["周杰倫"] }),
      weights({ favoriteArtists: ["林俊傑"] }),
    ),
    0,
  );
  assert.equal(
    sharedInterestScore(
      weights({ favoriteArtists: ["周杰倫"] }),
      weights({ favoriteArtists: ["周杰倫"] }),
    ),
    100,
  );
});
