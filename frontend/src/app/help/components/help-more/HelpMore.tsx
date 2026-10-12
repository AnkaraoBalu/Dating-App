import { CommonContainer } from "../../../../components";
import { Reveal } from "../../../../components/reveal";
import * as S from "./HelpMore.styles";

const links = [
  {
    to: "/how-it-works",
    emoji: "🧭",
    title: "How it works",
    body: "From your first profile to a first hello, step by step.",
  },
  {
    to: "/community-guidelines",
    emoji: "🤝",
    title: "Community guidelines",
    body: "The kind of space we’re building together.",
  },
  {
    to: "/download",
    emoji: "📱",
    title: "Meet the app",
    body: "Where Matchify is available and what’s coming.",
  },
];

/** "Still curious?": a closing band pointing to the next most useful pages. */
export function HelpMore() {
  return (
    <S.Root>
      <CommonContainer>
        <Reveal>
          <S.Head>
            <h2>
              Still curious? <em>Keep exploring.</em>
            </h2>
          </S.Head>
        </Reveal>
        <S.Grid>
          {links.map((link, i) => (
            <Reveal key={link.to} delay={i * 0.1}>
              <S.Card to={link.to}>
                <span data-emoji aria-hidden="true">
                  {link.emoji}
                </span>
                <strong>{link.title}</strong>
                <p>{link.body}</p>
                <b aria-hidden="true">↗</b>
              </S.Card>
            </Reveal>
          ))}
        </S.Grid>
      </CommonContainer>
    </S.Root>
  );
}
