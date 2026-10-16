import { LegalDocument } from "../../components/legal-document";
import { privacySections, privacySummary } from "./data/privacy";
export function PrivacyPage() {
  return (
    <LegalDocument
      eyebrow="Privacy policy"
      title="Your privacy matters."
      updated="16 October 2026"
      summary={privacySummary}
      sections={privacySections}
      related={{ to: "/terms", label: "Terms of use" }}
    />
  );
}
