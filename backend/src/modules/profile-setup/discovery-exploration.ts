import { createHash } from "node:crypto";

/** Four relevance picks followed by one exploration pick from the lower-ranked
 * half. A stable member/day seed avoids shuffling cards on every request.
 * Call only after eligibility filtering; input is already relevance-ranked.
 */
export function mixDiscoveryExploration<T extends { id: string }>(
  ranked: readonly T[],
  seed: string,
): T[] {
  if (ranked.length <= 4) return [...ranked];
  const priority = (id: string) =>
    createHash("sha256")
      .update(JSON.stringify([seed, id]))
      .digest("hex");
  const exploration = ranked
    .slice(Math.ceil(ranked.length / 2))
    .map((person) => ({ person, priority: priority(person.id) }))
    .sort(
      (a, b) =>
        a.priority.localeCompare(b.priority) ||
        a.person.id.localeCompare(b.person.id),
    );
  const selected = new Set<string>();
  const result: T[] = [];
  let relevanceIndex = 0;
  let explorationIndex = 0;
  while (result.length < ranked.length) {
    let next: T | undefined;
    if (result.length % 5 === 4) {
      while (
        explorationIndex < exploration.length &&
        selected.has(exploration[explorationIndex].person.id)
      )
        explorationIndex++;
      next = exploration[explorationIndex++]?.person;
    }
    if (!next) {
      while (
        relevanceIndex < ranked.length &&
        selected.has(ranked[relevanceIndex].id)
      )
        relevanceIndex++;
      next = ranked[relevanceIndex++];
    }
    if (!next) break;
    selected.add(next.id);
    result.push(next);
  }
  return result;
}
