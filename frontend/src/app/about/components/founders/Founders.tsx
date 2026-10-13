import { useRef } from "react";
import type { CSSProperties } from "react";
import { Eyebrow, Heading } from "../../../../components/ui";
import {
  smooth,
  usePinnedProgress,
  useStaticScene,
} from "../../../../hooks/usePinnedScene";
import * as S from "./Founders.styles";

// Placeholder quotes and roles: replace with the founders' own words.
// Add `image: "/images/founders/<name>.png"` to show a portrait instead of the monogram.
const founders: {
  name: string;
  role: string;
  quote: string;
  image?: string;
}[] = [
  {
    name: "Vinod",
    role: "Co-founder",
    quote:
      "The best connections start with the little things you share, not a perfect profile. We built Just2 to make room for those.",
  },
  {
    name: "Ankarao",
    role: "Co-founder",
    quote:
      "Every feature we ship asks one question: does this help two people feel a little more like themselves?",
  },
];

const apply = (progress: number, el: HTMLElement) => {
  el.style.setProperty("--card-0", String(smooth(progress / 0.55)));
  el.style.setProperty("--card-1", String(smooth((progress - 0.12) / 0.55)));
};

/** Founder cards rise and swing into place as the section scrolls in. */
export function Founders() {
  const ref = useRef<HTMLElement>(null);
  const staticMode = useStaticScene();
  usePinnedProgress(ref, !staticMode, apply, "enter");

  return (
    <S.Root ref={ref} $static={staticMode}>
      <S.Intro>
        <Eyebrow>The people behind it</Eyebrow>
        <Heading>
          Built by people who
          <br />
          <em>believe in the hello.</em>
        </Heading>
      </S.Intro>
      <S.Cards>
        {founders.map((founder, i) => (
          <S.Card
            key={founder.name}
            style={
              {
                "--in": `var(--card-${i})`,
                "--dir": i === 0 ? -1 : 1,
              } as CSSProperties
            }
          >
            <S.Portrait>
              {founder.image ? (
                <img src={founder.image} alt={founder.name} loading="lazy" />
              ) : (
                <span aria-hidden="true">{founder.name[0]}</span>
              )}
            </S.Portrait>
            <blockquote>
              <p>{founder.quote}</p>
              <footer>
                <span data-signature>{founder.name}</span>
                <cite>
                  {founder.name}, {founder.role}
                </cite>
              </footer>
            </blockquote>
          </S.Card>
        ))}
      </S.Cards>
    </S.Root>
  );
}
