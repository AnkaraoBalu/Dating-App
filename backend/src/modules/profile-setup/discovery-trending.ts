/** A bounded product ranking, not a public popularity/compatibility score.
 * Recent likes decay out of the query after seven days. Activity and a small
 * newcomer boost give active/new members a chance without lifetime popularity.
 */
export function discoveryTrendingScore(input: {
  recentLikes: number;
  lastActiveAt: Date | null;
  createdAt: Date;
  now: Date;
}): number {
  const daysAgo = (date: Date) =>
    Math.max(
      0,
      Math.floor((input.now.getTime() - date.getTime()) / 86_400_000),
    );
  const engagement =
    Math.log1p(Math.min(20, Math.max(0, input.recentLikes))) / Math.log1p(20);
  const activity = input.lastActiveAt
    ? Math.max(0, 1 - daysAgo(input.lastActiveAt) / 7)
    : 0;
  const newcomer = Math.max(0, 1 - daysAgo(input.createdAt) / 7);
  return 50 * engagement + 40 * activity + 10 * newcomer;
}
