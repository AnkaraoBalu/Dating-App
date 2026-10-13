import { useRef } from "react";
import type { CSSProperties } from "react";
import { ButtonLink } from "../../../../components/ui";
import {
  smooth,
  usePinnedProgress,
  useStaticScene,
} from "../../../../hooks/usePinnedScene";
import * as S from "./WelcomeGallery.styles";

// Resting offset from the centre of the stage; cards fly in from further out along the same line.
const cards = [
  {
    image: "maya",
    alt: "Illustrative golden-hour portrait",
    x: "-26vw",
    y: "-23svh",
    r: -12,
  },
  {
    image: "noah",
    alt: "Illustrative portrait outdoors",
    x: "26vw",
    y: "-21svh",
    r: 11,
  },
  {
    image: "leo",
    alt: "Illustrative portrait with friends",
    x: "-33vw",
    y: "26svh",
    r: -8,
  },
  {
    image: "aarav",
    alt: "Illustrative café portrait",
    x: "31vw",
    y: "27svh",
    r: 9,
  },
];

const apply = (progress: number, el: HTMLElement) => {
  el.style.setProperty("--in", String(smooth(progress / 0.75)));
  el.style.setProperty("--text", String(smooth((progress - 0.2) / 0.4)));
};

/** Pinned closing scene: photos arrive from the four corners around a welcome. */
export function WelcomeGallery() {
  const ref = useRef<HTMLElement>(null);
  const staticMode = useStaticScene();
  usePinnedProgress(ref, !staticMode, apply, "enter");

  return (
    <S.Root ref={ref} $static={staticMode}>
      <S.Stage $static={staticMode}>
        <S.Cards $static={staticMode}>
          {cards.map((card) => (
            <S.Card
              key={card.image}
              style={
                {
                  "--x": card.x,
                  "--y": card.y,
                  "--r": `${card.r}deg`,
                } as CSSProperties
              }
            >
              <img
                src={`/images/${card.image}.png`}
                alt={card.alt}
                loading="lazy"
              />
            </S.Card>
          ))}
        </S.Cards>
        <S.Copy>
          <span data-script>Welcome to</span>
          <h2>
            your kind of
            <br />
            <em>connection.</em>
          </h2>
          <p>
            Start with what makes you, you. See where a little curiosity can
            take you.
          </p>
          <ButtonLink to="/download">
            Meet Just2 <span aria-hidden="true">↗</span>
          </ButtonLink>
        </S.Copy>
      </S.Stage>
    </S.Root>
  );
}
