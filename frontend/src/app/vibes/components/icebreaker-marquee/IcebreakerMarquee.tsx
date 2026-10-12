import { useRef } from "react";
import {
  usePinnedProgress,
  useStaticScene,
} from "../../../../hooks/usePinnedScene";
import { icebreakers, vibes } from "../../data/vibes";
import * as S from "./IcebreakerMarquee.styles";

const apply = (progress: number, el: HTMLElement) => {
  el.style.setProperty("--drift", String(progress));
};

/** Two big rows of game and vibe names that slide in opposite directions as you scroll past. */
export function IcebreakerMarquee() {
  const ref = useRef<HTMLElement>(null);
  const staticMode = useStaticScene();
  usePinnedProgress(ref, !staticMode, apply, "enter");

  const rows = [
    icebreakers.map((g) => ({ text: g, mark: "✳" })),
    vibes.map((v) => ({ text: v.title, mark: v.emoji })),
  ];
  return (
    <S.Root ref={ref} aria-label="Icebreaker games and vibes">
      <S.Lead>A little fun makes every connection easier.</S.Lead>
      {rows.map((row, r) => (
        <S.Row key={r} $reverse={r === 1} aria-hidden="true">
          <div>
            {[...row, ...row, ...row].map((item, i) => (
              <span key={i}>
                <b>{item.mark}</b>
                {item.text}
              </span>
            ))}
          </div>
        </S.Row>
      ))}
    </S.Root>
  );
}
