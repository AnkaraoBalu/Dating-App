export const questions = [
  {
    id: "start",
    category: "Getting started",
    question: "How do I get started with Just2?",
    answer:
      "Sign in to the mobile app, complete your onboarding, and set up your profile with photos and details. Once your profile is ready, you can explore Discover and Vibes.",
  },
  {
    id: "matching",
    category: "Getting started",
    question: "How does a match happen?",
    answer:
      "A match happens when two people like each other. You can then open a conversation from Matches or Chat.",
  },
  {
    id: "vibes",
    category: "Vibes",
    question: "What are Vibes?",
    answer:
      "Vibes bring people together around shared interests. Explore rooms and find a topic that gives you a natural place to start.",
  },
  {
    id: "profile",
    category: "Profile",
    question: "Can I change my photos and profile?",
    answer:
      "Yes. Open your Profile tab to edit details, manage photos, and preview your profile.",
  },
  {
    id: "filters",
    category: "Profile",
    question: "Can I refine who I discover?",
    answer:
      "Discover includes filters and interests to help you explore people. The available controls are shown inside the app.",
  },
  {
    id: "chat",
    category: "Conversations",
    question: "Why do messages disappear?",
    answer:
      "Direct chats use After Viewing behavior. Received messages that have been marked read can disappear for both people when the recipient leaves the conversation or backgrounds the app. Deletion requires the leave request to reach the server; unread and saved messages stay.",
  },
  {
    id: "save",
    category: "Conversations",
    question: "How does Save in Chat work?",
    answer:
      "Long-press a delivered message and choose Save in Chat. A saved indicator is visible to both people, and the message is protected from automatic deletion. Either participant can save or unsave it.",
  },
  {
    id: "unsave",
    category: "Conversations",
    question: "What happens when I unsave a message?",
    answer:
      "The message becomes eligible for deletion when the recipient next leaves the chat. Unsaving does not immediately delete it.",
  },
  {
    id: "notifications",
    category: "Conversations",
    question: "How do notifications work?",
    answer:
      "Enable notification permission on your device to receive app alerts. Tapping a message notification opens the relevant conversation. Your operating system’s notification settings can affect delivery and presentation.",
  },
  {
    id: "availability",
    category: "Getting started",
    question: "Where can I download the app?",
    answer:
      "Visit our Meet the App page for availability. Store links will appear there when they are published. This website currently introduces the mobile experience.",
  },
  {
    id: "create-room",
    category: "Vibes",
    question: "Can I create my own Vibe room?",
    answer:
      "Yes. If you can’t find your vibe, create a room, pick its mood, and invite people in. Room hosts can manage the room’s settings.",
  },
  {
    id: "icebreakers",
    category: "Vibes",
    question: "What are icebreaker games?",
    answer:
      "Quick games you can play together in a Vibe room, like Would You Rather?, This or That, and Two Truths and a Lie. A little fun makes every connection easier.",
  },
  {
    id: "save-room",
    category: "Vibes",
    question: "Can I keep track of rooms I like?",
    answer: "Yes. Save a room to find it again later from your saved rooms.",
  },
] as const;

export const topics = [
  {
    name: "Getting started",
    emoji: "👋",
    blurb: "Sign in, set up, and find your way around.",
  },
  {
    name: "Profile",
    emoji: "🪞",
    blurb: "Photos, details, and how others discover you.",
  },
  {
    name: "Conversations",
    emoji: "💬",
    blurb: "Messages that disappear, saving, notifications.",
  },
  {
    name: "Vibes",
    emoji: "✨",
    blurb: "Rooms, icebreaker games, and creating your own.",
  },
] as const;

export const popular = ["matching", "chat", "save", "vibes"] as const;
