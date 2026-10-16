import type { LegalSection } from "../../../components/legal-document";

// Written from how the app works today. Have it reviewed by a lawyer as Just2
// grows, and keep it in step with the app and backend.
export const privacySummary = [
  "We collect what you give us (your profile, photos, and messages) and a little about how you use Just2.",
  "Your profile is shown to other members so you can connect. Your messages are only shared with the person you’re talking to.",
  "Viewed messages can disappear; saved messages stay until either of you unsaves them.",
  "We never sell your personal information.",
  "You can edit your profile or delete your account at any time.",
];

export const privacySections: LegalSection[] = [
  {
    id: "who-we-are",
    title: "Who we are",
    body: [
      "Just2 is operated by Ankarao Nakka, Somepalli, Tripuranthakam – 523326, India (“Just2”, “we”, “us”). We are responsible for the personal information described in this policy.",
      "Questions about privacy? Contact us at ankaraovinod@gmail.com.",
    ],
  },
  {
    id: "what-we-collect",
    title: "What we collect",
    body: [
      "Information you give us:",
      [
        "Account details, such as your email address or phone number, handled through our sign-in provider.",
        "Profile details: your name, age, gender, photos, interests, prompts, languages, and other details you choose to add.",
        "Messages, photos, and one-time location shares you send in conversations.",
        "Vibe rooms you create, join, or save, and what you post in them.",
        "Reports you make about other members.",
      ],
      "Information created as you use Just2:",
      [
        "Likes and passes, matches, and the rooms you take part in.",
        "Your approximate location, if you allow it, to show you people nearby and to filter by distance.",
        "Device information and a notification token, if you turn on notifications.",
        "Basic technical and security logs, such as when you sign in.",
      ],
    ],
  },
  {
    id: "face-verification",
    title: "Selfie verification",
    body: [
      "Selfie verification is not offered in the app yet, and we do not collect face or other biometric information.",
      "If we add verification later, it will be optional, we will ask for your permission first, and we will update this policy before it starts.",
    ],
  },
  {
    id: "how-we-use",
    title: "How we use your information",
    body: [
      [
        "To create and run your account and show your profile to other members.",
        "To suggest people and rooms, and to apply the discovery filters you choose (like age, distance, and interests).",
        "To deliver messages and notifications.",
        "To keep Just2 safe: preventing spam, fraud, and abuse, and reviewing reports.",
        "To fix problems and improve the service.",
        "To meet our legal obligations.",
      ],
      "We use your information because you ask us to provide Just2 to you, and with the consent you give when you create your account and allow permissions such as location, camera, microphone and notifications. You can withdraw consent by changing those permissions or deleting your account.",
    ],
  },
  {
    id: "who-sees-what",
    title: "Who can see your information",
    body: [
      "Other members can see your profile, including your photos, interests, and approximate distance. Members in a Vibe room can see what you share there.",
      "Messages are only visible to the people in the conversation. A one-time location share is only sent to the person you share it with.",
      "Members can block or report you, and you can block or report them.",
    ],
  },
  {
    id: "disappearing-messages",
    title: "Disappearing and saved messages",
    body: [
      "Direct chats use After Viewing behavior. Received messages that have been read can be deleted for both people when the recipient leaves the conversation or puts the app in the background.",
      "Unread messages and messages either person has saved stay in the conversation. Unsaving a message makes it eligible for deletion the next time the recipient leaves.",
      "Remember that the other person can always copy or screenshot what you send.",
    ],
  },
  {
    id: "sharing",
    title: "Service providers we share with",
    body: [
      "We use trusted providers to run Just2. They may only use your information to provide their service to us:",
      [
        "Sign-in and account security: Clerk.",
        "Photo and image storage: Cloudinary.",
        "Voice calls and live Vibe rooms: LiveKit.",
        "Push notifications: Firebase Cloud Messaging (Google).",
        "Hosting and database: Render and Neon.",
        "Email for support and safety reports: our email provider.",
      ],
      "We may also share information if required by law, to protect someone’s safety, or as part of a merger or sale of our business. We do not sell your personal information.",
    ],
  },
  {
    id: "retention",
    title: "How long we keep it",
    body: [
      "We keep your information while your account is active.",
      "When you delete your account, we delete it right away: your profile, photos, prompts, likes, passes, matches, chats and voice messages, blocks and reports, Vibe rooms, and your sign-in. Copies can remain in our providers’ automatic backups and logs for up to 30 days before they are erased.",
      "If the law requires us to keep something longer, for example to respond to a valid legal request, we keep only what is needed for as long as needed.",
    ],
  },
  {
    id: "your-choices",
    title: "Your choices and rights",
    body: [
      [
        "Edit your profile, photos, and details at any time in the app.",
        "Turn location and notifications on or off in your device settings.",
        "Delete your account in the app (Profile → Settings → Delete account), or request deletion without the app at just2.in/delete-account.",
        "Ask us for a copy of your information, or to correct or delete it, by contacting ankaraovinod@gmail.com.",
      ],
      "Depending on where you live, you may have additional rights, including the right to complain to your local data protection authority.",
    ],
  },
  {
    id: "security",
    title: "Security",
    body: [
      "We use reasonable technical and organizational measures to protect your information, such as encrypted connections and access controls. No service can be completely secure, so please use a strong sign-in and keep your device protected.",
    ],
  },
  {
    id: "age",
    title: "Age requirement",
    body: [
      "Just2 is only for adults aged 18 or older. We do not knowingly collect information from anyone under that age. If you believe a minor is using Just2, please report them in the app or contact us.",
    ],
  },
  {
    id: "changes",
    title: "Changes to this policy",
    body: [
      "We’ll update this page when our practices change and let you know in the app if the changes are significant.",
    ],
  },
];
