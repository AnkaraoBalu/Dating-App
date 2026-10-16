import { LegalDocument, type LegalSection } from "../../components/legal-document";
import { support } from "../../constants/support";

const summary = [
  "Just2 is for adults aged 18 and over only.",
  "We have zero tolerance for child sexual abuse and exploitation (CSAE) and child sexual abuse material (CSAM).",
  "Anyone can report a profile, photo or message in the app; reports reach our safety team.",
  "We remove offending content and accounts, and report CSAM to the relevant authorities.",
];

const sections: LegalSection[] = [
  {
    id: "standards",
    title: "Our standards",
    body: [
      "Just2, the dating app operated by Ankarao Nakka, prohibits any content or behaviour that sexually exploits, abuses or endangers children. This includes:",
      [
        "Child sexual abuse material (CSAM) of any kind, including drawn, AI-generated or edited images.",
        "Grooming, sexualising or soliciting minors, or arranging to meet a minor.",
        "Sextortion, trafficking, or any attempt to exploit a child.",
        "Accounts created by, or on behalf of, anyone under 18.",
      ],
    ],
  },
  {
    id: "age",
    title: "Adults only",
    body: [
      "Members must be 18 or older. Every member enters their date of birth during sign-up, and the app and our servers reject anyone under 18. Profiles that appear to belong to a minor can be reported with the “May be under 18” reason and are removed.",
    ],
  },
  {
    id: "reporting",
    title: "How to report",
    body: [
      "In the app, open the profile, chat or match, tap the ⋯ menu, choose Report, and select a reason such as “May be under 18”. Reporting also blocks the person for you.",
      `You can also email ${support.email} with the subject “Child safety report”. Include the member’s name or a description, and any details that help us find them.`,
      "If a child is in immediate danger, contact your local police or emergency services first. In India you can also call the Childline helpline at 1098 or report at cybercrime.gov.in.",
    ],
  },
  {
    id: "action",
    title: "What we do",
    body: [
      [
        "Reports are sent to our safety team, who review child-safety reports first.",
        "We remove CSAM and offending profiles, and permanently ban the accounts involved.",
        "We report CSAM and child exploitation to the relevant authorities, including the National Center for Missing & Exploited Children (NCMEC) and Indian law enforcement, as required by law.",
        "We cooperate with law enforcement requests in line with applicable law.",
      ],
    ],
  },
  {
    id: "contact",
    title: "Child safety contact",
    body: [
      `Our designated child safety contact is Ankarao Nakka, reachable at ${support.email} or ${support.phone}. This contact can speak to our CSAE prevention practices and compliance.`,
    ],
  },
];

/** Child safety standards page required by Google Play for dating apps. */
export function ChildSafetyPage() {
  return (
    <LegalDocument
      eyebrow="Child safety standards"
      title="Keeping children safe."
      updated="16 October 2026"
      summary={summary}
      sections={sections}
      related={{ to: "/community-guidelines", label: "Community guidelines" }}
    />
  );
}
