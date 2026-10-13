import { CommonContainer } from "../../components";
import { Eyebrow, TextLink } from "../../components/ui";
import { ChatDemo } from "../../components/chat-demo";
import * as S from "./DownloadPage.styles";
export function DownloadPage() {
  return (
    <CommonContainer>
      <S.Layout>
        <div>
          <Eyebrow>Meet the mobile experience</Eyebrow>
          <h1>
            A little hello.
            <br />
            <em>A world of possibility.</em>
          </h1>
          <p data-copy>
            Discover people, follow your interests, and make room for a
            connection that feels like you. Just2 brings it together in one
            place.
          </p>
          <S.Stores aria-label="App availability">
            <div>
              <strong>iPhone</strong>
              <small>App Store link coming soon</small>
            </div>
            <div>
              <strong>Android</strong>
              <small>Google Play link coming soon</small>
            </div>
          </S.Stores>
          <S.Note>
            Download links aren’t available on this website yet. In the
            meantime, explore the experience and try the chat preview.
          </S.Note>
          <TextLink to="/how-it-works">Explore how it works →</TextLink>
        </div>
        <ChatDemo />
      </S.Layout>
    </CommonContainer>
  );
}
