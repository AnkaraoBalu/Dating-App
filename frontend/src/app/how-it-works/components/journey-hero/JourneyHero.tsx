import { useRef } from "react";
import type { CSSProperties } from "react";
import { Eyebrow } from "../../../../components/ui";
import {
  smooth,
  usePinnedProgress,
  useStaticScene,
} from "../../../../hooks/usePinnedScene";
import * as S from "./JourneyHero.styles";

// Where each step chip floats at first (around the headline) and its slot in the final row.
export const journeySteps = [
  { icon: "☺", label: "Make it yours", sx: "-31vw", sy: "-20svh", r: -10 },
  { icon: "✳", label: "Find common ground", sx: "-27vw", sy: "22svh", r: 7 },
  { icon: "♡", label: "A mutual yes", sx: "30vw", sy: "-23svh", r: 8 },
  { icon: "✉", label: "Say hello", sx: "29vw", sy: "19svh", r: -8 },
];

const apply = (progress: number, el: HTMLElement) => {
  el.style.setProperty("--a", String(smooth(progress / 0.5)));
  el.style.setProperty("--b", String(smooth((progress - 0.42) / 0.38)));
};

/** Pinned hero: floating step chips gather into a row and a line draws through them. */
export function JourneyHero() {
  const ref = useRef<HTMLElement>(null);
  const staticMode = useStaticScene();
  usePinnedProgress(ref, !staticMode, apply);

  return (
    <S.Root ref={ref} $static={staticMode}>
      <S.Stage $static={staticMode}>
        <S.Title>
          <Eyebrow>How it works</Eyebrow>
          <h1>
            From a little curiosity
            <br />
            to <em>a first hello.</em>
          </h1>
        </S.Title>
        <S.Path
          viewBox="0 0 810 70"
          preserveAspectRatio="none"
          aria-hidden="true"
        >
          <path
            d="M4 35 C 110 4, 160 66, 270 35 S 430 4, 540 35 S 700 66, 806 35"
            pathLength={1}
          />
        </S.Path>
        <S.Steps>
          {journeySteps.map((step, i) => (
            <S.Step
              key={step.label}
              style={
                {
                  "--i": i,
                  "--sx": step.sx,
                  "--sy": step.sy,
                  "--r": `${step.r}deg`,
                } as CSSProperties
              }
            >
              <span data-icon aria-hidden="true">
                {step.icon}
              </span>
              <span data-text>
                <small>0{i + 1}</small>
                {step.label}
              </span>
            </S.Step>
          ))}
        </S.Steps>
        <S.Copy>
          Make a profile that feels like you, discover your kind of people, and
          start a conversation when the feeling is mutual.
        </S.Copy>
        <S.Hint aria-hidden="true">Scroll to see how ↓</S.Hint>
      </S.Stage>
    </S.Root>
  );
}
