import { Route, Routes } from "react-router-dom";
import { WebsiteLayout } from "../layouts/website-layout";
import { HomePage } from "../app/home";
import { AboutPage } from "../app/about";
import { HowItWorksPage } from "../app/how-it-works";
import { VibesPage } from "../app/vibes";
import { HelpPage } from "../app/help";
import { SupportPage } from "../app/support";
import { DownloadPage } from "../app/download";
import { CommunityPage } from "../app/community-guidelines";
import { PrivacyPage } from "../app/privacy";
import { TermsPage } from "../app/terms";
import { DeleteAccountPage } from "../app/delete-account";
import { ChildSafetyPage } from "../app/child-safety";
import { NotFoundPage } from "../app/not-found";
export function AppRouter() {
  return (
    <Routes>
      <Route element={<WebsiteLayout />}>
        <Route index element={<HomePage />} />
        <Route path="about" element={<AboutPage />} />
        <Route path="how-it-works" element={<HowItWorksPage />} />
        <Route path="vibes" element={<VibesPage />} />
        <Route path="help" element={<HelpPage />} />
        <Route path="support" element={<SupportPage />} />
        <Route path="download" element={<DownloadPage />} />
        <Route path="community-guidelines" element={<CommunityPage />} />
        <Route path="privacy" element={<PrivacyPage />} />
        <Route path="terms" element={<TermsPage />} />
        <Route path="delete-account" element={<DeleteAccountPage />} />
        <Route path="child-safety" element={<ChildSafetyPage />} />
        <Route path="*" element={<NotFoundPage />} />
      </Route>
    </Routes>
  );
}
