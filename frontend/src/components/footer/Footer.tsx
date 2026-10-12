import { Link, useLocation } from "react-router-dom";
import { CommonContainer } from "../common-container";
import { FallingFaces } from "./FallingFaces";
import * as S from "./Footer.styles";
export function Footer() {
  // Remount the pit on each page so the faces fall in fresh there too.
  const { pathname } = useLocation();
  return (
    <S.Root>
      <S.Panel>
        <CommonContainer>
          <S.Top>
            <S.Brand>
              <Link to="/" aria-label="Matchify home">
                matchify<span aria-hidden="true">✳</span>
              </Link>
              <p>
                Find your people.
                <br />
                And a little more of yourself along the way.
              </p>
            </S.Brand>
            <nav aria-label="Footer navigation">
              <div>
                <strong>Explore</strong>
                <Link to="/about">Our story</Link>
                <Link to="/how-it-works">How it works</Link>
                <Link to="/vibes">Find your vibe</Link>
                <Link to="/download">The app</Link>
              </div>
              <div>
                <strong>Good to know</strong>
                <Link to="/help">Help center</Link>
                <Link to="/community-guidelines">Community</Link>
                <Link to="/privacy">Privacy</Link>
                <Link to="/terms">Terms</Link>
              </div>
            </nav>
          </S.Top>
        </CommonContainer>
      </S.Panel>
      <S.Band>
        <S.Wordmark aria-hidden="true">
          matchify<span>✳</span>
        </S.Wordmark>
        <FallingFaces key={pathname} />
      </S.Band>
      <S.Bottom>
        <span>© {new Date().getFullYear()} Matchify</span>
        <span>Made for the possibility of something real.</span>
      </S.Bottom>
    </S.Root>
  );
}
