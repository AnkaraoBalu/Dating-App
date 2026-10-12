import { useRef } from "react";
import type { CSSProperties } from "react";
import { ButtonLink } from "../../../../components/ui";
import {
  smooth,
  usePinnedProgress,
  useStaticScene,
} from "../../../../hooks/usePinnedScene";
import * as S from "./HomeFinale.styles";

// Starting angle on the orbit and size for each face.
const faces = [
  { image: "maya", angle: 200, size: 118 },
  { image: "leo", angle: 255, size: 92 },
  { image: "zoe", angle: 320, size: 108 },
  { image: "aarav", angle: 20, size: 120 },
  { image: "leah", angle: 85, size: 96 },
  { image: "noah", angle: 145, size: 104 },
];

const apply = (progress: number, el: HTMLElement) => {
  el.style.setProperty("--spread", String(smooth(progress / 0.55)));
  el.style.setProperty("--spin", String(progress));
  el.style.setProperty("--text", String(smooth((progress - 0.22) / 0.35)));
  el.style.setProperty("--cta", String(smooth((progress - 0.45) / 0.2)));
};

/** Closing scene: faces spread from the spark into a slowly turning orbit around the call to action. */
export function HomeFinale() {
  const ref = useRef<HTMLElement>(null);
  const staticMode = useStaticScene();
  usePinnedProgress(ref, !staticMode, apply, "enter");

  return (
    <S.Root ref={ref} id="meet-matchify" tabIndex={-1} $static={staticMode}>
      <S.Stage $static={staticMode}>
        <S.Orbit $static={staticMode} aria-hidden="true">
          {faces.map((face) => (
            <img
              key={face.image}
              src={`/images/${face.image}.png`}
              alt=""
              loading="lazy"
              style={
                {
                  "--angle": `${face.angle}deg`,
                  "--size": `${face.size}px`,
                } as CSSProperties
              }
            />
          ))}
        </S.Orbit>
        <S.Copy>
          <span data-spark aria-hidden="true">
            ✳
          </span>
          <h2>
            Someone out there
            <br />
            gets <em>your kind of weird.</em>
          </h2>
          <p>
            Start with what makes you, you. See where a little curiosity can
            take you.
          </p>
          <div data-cta>
            <ButtonLink to="/download">
              Meet Matchify <span aria-hidden="true">↗</span>
            </ButtonLink>
          </div>
        </S.Copy>
      </S.Stage>
    </S.Root>
  );
}
