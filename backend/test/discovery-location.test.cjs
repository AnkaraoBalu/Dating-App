const test = require("node:test");
const assert = require("node:assert/strict");
const fs = require("node:fs");
const path = require("node:path");
const {
  discoveryCityCenter,
} = require("../dist/src/modules/profile-setup/discovery-location.js");

const travelScreen = path.join(
  __dirname,
  "../../DatingAPP/lib/features/home/presentation/screens/discover_travel_screen.dart",
);

test("every city on the app's travel screen has a search center", () => {
  const source = fs.readFileSync(travelScreen, "utf8");
  const cities = [...source.matchAll(/^\s*\('([^']+)',\s*'[^']+',/gm)].map(
    (match) => match[1],
  );
  assert.ok(cities.length >= 30, `found only ${cities.length} cities`);
  for (const city of cities) {
    assert.ok(discoveryCityCenter(city), `${city} is missing a center`);
  }
});

test("older spellings and casing resolve to the same city", () => {
  assert.deepEqual(
    discoveryCityCenter(" Bengaluru "),
    discoveryCityCenter("Bangalore"),
  );
  assert.deepEqual(
    discoveryCityCenter("GURGAON"),
    discoveryCityCenter("Gurugram"),
  );
  assert.equal(discoveryCityCenter("Atlantis"), undefined);
  assert.equal(discoveryCityCenter("constructor"), undefined);
});
