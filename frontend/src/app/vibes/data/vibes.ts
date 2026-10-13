// Vibe categories as they appear in the Just2 app. Messages are illustrative.
export const vibes = [
  {
    id: "coffee",
    group: "Slow & cozy",
    emoji: "☕",
    title: "Coffee & Chats",
    description:
      "Slow mornings, favorite corners, and conversations without a rush.",
    cover: "/images/vibes/coffee_chats.jpg",
    message: "Oat flat white or classic cappuccino? Defend your order.",
  },
  {
    id: "late-night",
    group: "Slow & cozy",
    emoji: "🌙",
    title: "Late Night Talks",
    description: "For the thoughts that only show up after midnight.",
    cover: "/images/vibes/late_night_talks.jpg",
    message: "What’s a small thing that made you happy this week?",
  },
  {
    id: "music",
    group: "Slow & cozy",
    emoji: "🎵",
    title: "Music & Chill",
    description: "The song you can’t stop sharing, and the people who get it.",
    cover: "/images/vibes/live_music.jpg",
    message: "Drop the last song you had on repeat. No skipping.",
  },
  {
    id: "study",
    group: "Slow & cozy",
    emoji: "📚",
    title: "Study Dates",
    description:
      "Quiet focus, good company, and a coffee break worth waiting for.",
    cover: "/images/vibes/study_dates.jpg",
    message: "25 minutes of focus, then we compare notes?",
  },
  {
    id: "food",
    group: "Out & about",
    emoji: "🍜",
    title: "Food Adventures",
    description: "Hidden gems, street food runs, and the best bowl in town.",
    cover: "/images/vibes/food_adventures.jpg",
    message: "Best ramen spot you’ve found so far. Go.",
  },
  {
    id: "travel",
    group: "Out & about",
    emoji: "✈️",
    title: "Travel Buddies",
    description: "Weekend trips, dream routes, and window-seat stories.",
    cover: "/images/vibes/mountain_travel.jpg",
    message: "Mountains or beach for a last-minute weekend?",
  },
  {
    id: "random",
    group: "Out & about",
    emoji: "✨",
    title: "Random Plans",
    description: "No plans, good plans. See where the day takes you.",
    cover: "/images/vibes/city_exploration.jpg",
    message: "Who’s up for a sunset walk and zero agenda?",
  },
  {
    id: "romantic",
    group: "Play & spark",
    emoji: "💗",
    title: "Feeling Romantic",
    description: "For hopeless romantics and the little gestures that count.",
    cover: "/images/vibes/romantic_dinner.jpg",
    message: "Handwritten notes: cute or too much?",
  },
  {
    id: "gaming",
    group: "Play & spark",
    emoji: "🎮",
    title: "Gaming Together",
    description: "Co-op nights, friendly rivalries, and one more round.",
    cover: "/images/vibes/arcade_games.jpg",
    message: "Co-op or competitive? Choose wisely.",
  },
] as const;

export const vibeGroups = [
  "All vibes",
  "Slow & cozy",
  "Out & about",
  "Play & spark",
] as const;

// Icebreaker games available inside Vibe rooms.
export const icebreakers = [
  "Would You Rather?",
  "This or That",
  "Two Truths and a Lie",
  "Red Flag / Green Flag",
  "Guess My Vibe",
  "Chemistry Check",
] as const;
