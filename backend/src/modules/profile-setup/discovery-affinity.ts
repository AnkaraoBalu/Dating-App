type InterestPreferences = {
  interests: string[];
  musicGenres: string[];
  favoriteArtists: string[];
};

// Keep Unicode names and collapse casing, spacing and punctuation differences.
export function normalizeDiscoveryInterest(value: string): string {
  return value
    .normalize("NFKC")
    .toLowerCase()
    .replace(/[^\p{L}\p{N}]/gu, "");
}

/** Product weights: shared activities matter most, followed by artists, then genres. */
export function discoveryInterestWeights(
  profile: InterestPreferences,
): Map<string, number> {
  const features = new Map<string, number>();
  const groups = [
    ["interest", profile.interests, 3],
    ["artist", profile.favoriteArtists, 2],
    ["genre", profile.musicGenres, 1],
  ] as const;
  for (const [category, values, weight] of groups) {
    for (const value of values) {
      const normalized = normalizeDiscoveryInterest(value);
      if (normalized) features.set(`${category}:${normalized}`, weight);
    }
  }
  return features;
}

/** Weighted Jaccard overlap: symmetric, deduplicated and bounded from 0 to 100.
 * This describes shared interests, not predicted relationship compatibility.
 */
export function sharedInterestScore(
  a: Map<string, number>,
  b: Map<string, number>,
): number {
  let shared = 0;
  let total = 0;
  for (const key of new Set([...a.keys(), ...b.keys()])) {
    shared += Math.min(a.get(key) ?? 0, b.get(key) ?? 0);
    total += Math.max(a.get(key) ?? 0, b.get(key) ?? 0);
  }
  return total ? Math.round((shared / total) * 100) : 0;
}
