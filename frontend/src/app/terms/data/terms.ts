import type { LegalSection } from "../../../components/legal-document";

// Written from how the app works today. Have it reviewed by a lawyer as Just2
// grows, and keep it in step with the app.
export const termsSummary = [
  "You must be 18 or older to use Just2.",
  "Be honest, be kind, and follow our community guidelines.",
  "You own what you post; you let us show it so Just2 can work.",
  "We can remove content or accounts that break these terms.",
  "You can stop using Just2 and delete your account at any time.",
];

export const termsSections: LegalSection[] = [
  {
    id: "agreement",
    title: "Agreeing to these terms",
    body: [
      "These terms are an agreement between you and Ankarao Nakka, who operates Just2 (“Just2”, “we”, “us”). By creating an account or using Just2, you agree to them and to our Privacy Policy.",
    ],
  },
  {
    id: "eligibility",
    title: "Who can use Just2",
    body: [
      [
        "You are at least 18 years old.",
        "You can legally enter into this agreement where you live.",
        "You haven’t been removed from Just2 before.",
        "You have one account, and it represents you.",
      ],
    ],
  },
  {
    id: "your-account",
    title: "Your account",
    body: [
      "You’re responsible for keeping your sign-in secure and for activity on your account. Keep your profile accurate and up to date, and tell us if you think someone else has access to your account.",
    ],
  },
  {
    id: "community",
    title: "Community conduct",
    body: [
      "Just2 works when people feel safe and respected. You agree not to:",
      [
        "Harass, threaten, bully, or pressure anyone.",
        "Post hateful, sexually explicit, violent, or illegal content.",
        "Pretend to be someone else or misrepresent yourself.",
        "Use Just2 for spam, scams, advertising, or soliciting money.",
        "Share someone else’s private information or photos without permission.",
        "Interfere with Just2 or try to access it in unauthorized ways, such as scraping.",
      ],
      "Please also follow our Community guidelines. You can block or report anyone at any time.",
    ],
  },
  {
    id: "content",
    title: "Your content",
    body: [
      "You keep ownership of the photos, profile details, and messages you share. To run Just2, you give us a [worldwide, non-exclusive, royalty-free] license to host, store, display, and process that content for as long as it’s on Just2.",
      "Only post content you have the right to share. You’re responsible for what you post.",
    ],
  },
  {
    id: "features",
    title: "Matches, chats, and Vibe rooms",
    body: [
      "A match happens when two members like each other, and only matches can start a conversation.",
      "Read messages can disappear when the recipient leaves the chat, unless either person saves them. We can’t guarantee that content will be available later, and others may still copy what you send.",
      "Vibe room hosts can manage their rooms. Rooms and what’s shared in them must follow these terms.",
    ],
  },
  {
    id: "safety",
    title: "Meeting people safely",
    body: [
      "We don’t run criminal background checks on members, and we can’t guarantee anyone’s identity or intentions. Optional selfie verification can help, but it isn’t a guarantee. Take your time, meet in public places, and tell a friend your plans.",
    ],
  },
  {
    id: "enforcement",
    title: "Removing content and accounts",
    body: [
      "We may review reports and remove content, restrict features, or suspend or close accounts that break these terms or put others at risk. Where appropriate, we’ll tell you why.",
    ],
  },
  {
    id: "ending",
    title: "Ending your account",
    body: [
      "You can delete your account at any time from your profile options. Some information may be kept as described in our Privacy Policy.",
    ],
  },
  {
    id: "disclaimers",
    title: "Disclaimers and liability",
    body: [
      "Just2 is provided “as is” and “as available”. We work to keep it safe and running, but we can’t promise it will always be available or error-free.",
      "We don’t run background checks on members and aren’t responsible for how members behave, on or off Just2. Take care when meeting someone: meet in a public place, tell a friend, and report anything that worries you.",
      "To the extent the law allows, we are not liable for indirect or consequential losses, and our total liability to you is limited to the amount you have paid us in the last 12 months (Just2 is currently free). Nothing in these terms limits liability that cannot be limited by law.",
    ],
  },
  {
    id: "law",
    title: "Governing law and disputes",
    body: [
      "These terms are governed by the laws of India.",
      "If you have a problem with Just2, please contact us first at ankaraovinod@gmail.com and we’ll try to resolve it. If we can’t, disputes will be handled by the competent courts in Andhra Pradesh, India.",
    ],
  },
  {
    id: "changes",
    title: "Changes to these terms",
    body: [
      "We may update these terms as Just2 grows. If changes are significant, we’ll let you know in the app before they take effect. Questions? Contact us at ankaraovinod@gmail.com.",
    ],
  },
];
