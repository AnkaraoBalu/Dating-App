import { LegalDocument } from "../../components/legal-document";
import { termsSections, termsSummary } from "./data/terms";
export function TermsPage() {
  return (
    <LegalDocument
      eyebrow="Terms of use"
      title="The details, clearly."
      updated="16 October 2026"
      summary={termsSummary}
      sections={termsSections}
      related={{ to: "/privacy", label: "Privacy policy" }}
    />
  );
}
