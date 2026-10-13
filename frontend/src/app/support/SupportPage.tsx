import { CommonContainer } from "../../components";
import { Eyebrow, TextLink } from "../../components/ui";
import { support } from "../../constants/support";
import * as S from "./SupportPage.styles";

const topics = [
  "Signing in or creating your account",
  "Your profile, photos, or verification",
  "Matches, chats, or Vibe rooms",
  "Reporting someone or a safety concern",
  "Deleting your account or your data",
];

/** Contact page used as the App Store / Google Play support URL. */
export function SupportPage() {
  return (
    <CommonContainer>
      <S.Layout>
        <div>
          <Eyebrow>Support</Eyebrow>
          <h1>
            We’re here to help.
            <br />
            <em>Just reach out.</em>
          </h1>
          <p data-copy>
            Something not working, or a question the help center doesn’t
            answer? Email or call us and a real person from the Just2 team will
            get back to you.
          </p>
          <S.Note>
            If you or someone else is in immediate danger, contact local
            emergency services first.
          </S.Note>
          <TextLink to="/help">Browse the help center →</TextLink>
        </div>
        <S.Contacts aria-label="Contact Just2 support">
          <S.Contact href={`mailto:${support.email}?subject=Just2%20support`}>
            <span data-emoji aria-hidden="true">
              ✉️
            </span>
            <small>Email us</small>
            <strong>{support.email}</strong>
            <p>Best for account, privacy, and deletion requests.</p>
          </S.Contact>
          <S.Contact href={support.phoneHref}>
            <span data-emoji aria-hidden="true">
              📞
            </span>
            <small>Call us</small>
            <strong>{support.phone}</strong>
            <p>Tap to call from your phone.</p>
          </S.Contact>
          <S.Topics>
            <strong>We can help with</strong>
            <ul>
              {topics.map((topic) => (
                <li key={topic}>{topic}</li>
              ))}
            </ul>
            <p>
              Include the email or phone number on your Just2 account so we can
              find it quickly.
            </p>
          </S.Topics>
        </S.Contacts>
      </S.Layout>
    </CommonContainer>
  );
}
