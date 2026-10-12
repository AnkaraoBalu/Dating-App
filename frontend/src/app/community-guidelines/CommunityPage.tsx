import { PageHero } from "../../components/page-hero";
import { CommonContainer } from "../../components";
import { AppCta } from "../../components/app-cta";
import { Principles } from "./CommunityPage.styles";
export function CommunityPage() {
  return (
    <>
      <PageHero
        eyebrow="Our community"
        title={
          <>
            Good connections start
            <br />
            with <em>good intentions.</em>
          </>
        }
        description="The kind of space we want to build together: thoughtful, welcoming, and grounded in respect."
      />
      <CommonContainer>
        <Principles>
          {[
            [
              "♡",
              "Be yourself, honestly.",
              "Choose photos and details that represent you. A real connection deserves a real starting point.",
            ],
            [
              "✳",
              "Make room for respect.",
              "Treat people with care, even when the feeling isn’t mutual. Harassment, hateful behavior, and pressure have no place in a good conversation.",
            ],
            [
              "↗",
              "Respect a different pace.",
              "A match is an invitation to talk. It is never an obligation to share, meet, or continue. Respect someone’s boundaries and their decision to step away.",
            ],
            [
              "⌁",
              "Keep private things private.",
              "Think before sharing personal information. Respect the privacy of the people you meet and ask before sharing their photos or conversations.",
            ],
          ].map(([icon, title, body]) => (
            <article key={title}>
              <span aria-hidden="true">{icon}</span>
              <div>
                <h2>{title}</h2>
                <p>{body}</p>
              </div>
            </article>
          ))}
        </Principles>
      </CommonContainer>
      <AppCta />
    </>
  );
}
