import { Outlet } from "react-router-dom";
import { Navbar, Footer } from "../../components";
import { RouteEffects } from "../../router/RouteEffects";
import { IntroSplash } from "../../components/intro-splash";
import { Main } from "./WebsiteLayout.styles";
export function WebsiteLayout() {
  return (
    <>
      <RouteEffects />
      <IntroSplash />
      <Navbar />
      <Main id="main-content" tabIndex={-1}>
        <Outlet />
      </Main>
      <Footer />
    </>
  );
}
