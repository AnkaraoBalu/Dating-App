import { CommonContainer } from "../../components";
import { Eyebrow, TextLink } from "../../components/ui";
import { support } from "../../constants/support";
import * as S from "../support/SupportPage.styles";

const deletionMail = `mailto:${support.email}?subject=Delete%20my%20Just2%20account`;

/**
 * Account deletion page for the Google Play "delete account" URL: how to
 * delete in the app or without it, and what is deleted or kept.
 */
export function DeleteAccountPage() {
  return (
    <CommonContainer>
      <S.Layout>
        <div>
          <Eyebrow>Delete your account</Eyebrow>
          <h1>
            Delete your Just2 account
            <br />
            <em>and your data.</em>
          </h1>
          <p data-copy>
            Just2, the dating app by Ankarao Nakka, lets you delete your account
            and its data at any time, in the app or by asking us here without
            the app.
          </p>
          <S.Note>
            Deletion is permanent. Your matches and chats can’t be restored, and
            you’d need to create a new account to use Just2 again.
          </S.Note>
          <TextLink to="/privacy">Read our privacy policy →</TextLink>
        </div>
        <S.Contacts aria-label="Request deletion without the app">
          <S.Contact href={deletionMail}>
            <span data-emoji aria-hidden="true">
              ✉️
            </span>
            <small>No app? Email us</small>
            <strong>{support.email}</strong>
            <p>
              Send “Delete my Just2 account” from the email address or phone
              number on your account. We confirm and delete it within 7 days.
            </p>
          </S.Contact>
        </S.Contacts>
      </S.Layout>
      <S.Deletion aria-labelledby="delete-steps-title">
        <h2 id="delete-steps-title">How deletion works</h2>
        <div>
          <section>
            <strong>In the app</strong>
            <ol>
              <li>Open Just2 and go to your Profile.</li>
              <li>Tap Settings, then Delete account.</li>
              <li>Confirm. Your account is deleted right away.</li>
            </ol>
          </section>
          <section>
            <strong>What we delete</strong>
            <p>
              Your profile, photos, prompts, interests and other details, your
              likes, passes and matches, chats, photos and voice messages you
              sent, blocks and reports, Vibe rooms, notification tokens, and
              your sign-in account.
            </p>
          </section>
          <section>
            <strong>What we keep, and for how long</strong>
            <p>
              Nothing is kept in Just2 itself. Copies can remain in our hosting
              providers’ automatic backups and logs for up to 30 days, then
              they are erased. If the law requires us to keep something longer,
              we keep only what is needed.
            </p>
          </section>
        </div>
      </S.Deletion>
    </CommonContainer>
  );
}
