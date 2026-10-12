import { useEffect, useRef } from "react";
import type { CSSProperties } from "react";
import { Eyebrow } from "../../../../components/ui";
import {
  smooth,
  usePinnedProgress,
  useStaticScene,
} from "../../../../hooks/usePinnedScene";
import { vibes } from "../../data/vibes";
import * as S from "./VibesHero.styles";

const apply = (progress: number, el: HTMLElement) => {
  el.style.setProperty("--gather", String(smooth(progress / 0.6)));
  el.style.setProperty("--more", String(smooth((progress - 0.5) / 0.3)));
};

/** Pinned hero: vibe bubbles spiral in from the edges into a ring around the headline. */
export function VibesHero() {
  const ref = useRef<HTMLElement>(null);
  const staticMode = useStaticScene();
  usePinnedProgress(ref, !staticMode, apply);

  // Bubbles lean gently toward the pointer, each by its own depth.
  useEffect(() => {
    const el = ref.current;
    if (!el || staticMode) return;
    let frame = 0;
    const move = (event: PointerEvent) => {
      if (event.pointerType !== "mouse" || frame) return;
      frame = requestAnimationFrame(() => {
        frame = 0;
        el.style.setProperty(
          "--mx",
          String((event.clientX / innerWidth) * 2 - 1),
        );
        el.style.setProperty(
          "--my",
          String((event.clientY / innerHeight) * 2 - 1),
        );
      });
    };
    addEventListener("pointermove", move);
    return () => {
      removeEventListener("pointermove", move);
      cancelAnimationFrame(frame);
    };
  }, [staticMode]);

  return (
    <S.Root ref={ref} $static={staticMode}>
      <S.Stage $static={staticMode}>
        <S.Bubbles $static={staticMode} aria-hidden="true">
          {vibes.map((vibe, i) => (
            <span
              key={vibe.id}
              style={
                {
                  "--angle": `${(i * 360) / vibes.length - 90}deg`,
                  "--depth": 0.6 + ((i * 37) % 10) / 10,
                  "--i": i,
                } as CSSProperties
              }
            >
              <b>{vibe.emoji}</b>
              {vibe.title}
            </span>
          ))}
        </S.Bubbles>
        <S.Title>
          <Eyebrow>What’s your vibe today?</Eyebrow>
          <h1>
            The things you love.
            <br />
            <em>The people who get it.</em>
          </h1>
          <p data-more>
            Vibe rooms bring people together around shared interests. Drop into
            one, say hello, and see who gets your energy.
          </p>
          <a data-more href="#rooms">
            Explore rooms ↓
          </a>
        </S.Title>
      </S.Stage>
    </S.Root>
  );
}
