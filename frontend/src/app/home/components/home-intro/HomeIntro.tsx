import { useRef } from "react";
import type { CSSProperties } from "react";
import { CommonContainer } from "../../../../components";
import { Eyebrow } from "../../../../components/ui";
import { ScrollMore } from "../../../../components/scroll-more";
import {
  smooth,
  usePinnedProgress,
  useStaticScene,
} from "../../../../hooks/usePinnedScene";
import * as S from "./HomeIntro.styles";

// Heading words; `null` is a line break, `accent` words are set in the serif italic.
const heading: ({ word: string; accent?: boolean } | null)[] = [
  ..."Noticing the same little things.".split(" ").map((word) => ({ word })),
  null,
  { word: "That’s" },
  { word: "where" },
  { word: "it", accent: true },
  { word: "begins.", accent: true },
];
const wordCount = heading.filter(Boolean).length;

// Floating interests: position in the stage and a depth that sets their parallax speed.
const chips = [
  { label: "Coffee dates", x: "9%", y: "20%", depth: 1.3, r: -6 },
  { label: "Shared playlists", x: "78%", y: "16%", depth: 0.8, r: 5 },
  { label: "Slow Sundays", x: "4%", y: "62%", depth: 0.9, r: 4 },
  { label: "Weekend adventures", x: "80%", y: "58%", depth: 1.4, r: -4 },
  { label: "Late-night talks", x: "20%", y: "80%", depth: 0.7, r: -3 },
  { label: "Real conversations", x: "66%", y: "80%", depth: 1.1, r: 6 },
];
const ticker = [
  "Coffee dates",
  "Shared playlists",
  "Weekend adventures",
  "Real conversations",
];

const apply = (progress: number, el: HTMLElement) => {
  el.style.setProperty("--chips", String(smooth(progress / 0.45)));
  el.style.setProperty("--reveal", String(smooth((progress - 0.18) / 0.5)));
  el.style.setProperty("--para", String(smooth((progress - 0.6) / 0.15)));
  el.style.setProperty("--note", String(smooth((progress - 0.68) / 0.18)));
  el.style.setProperty("--drift", String(progress));
};

/** Intro: the heading lights up word by word while interests drift around it. */
export function HomeIntro() {
  const ref = useRef<HTMLElement>(null);
  const staticMode = useStaticScene();
  usePinnedProgress(ref, !staticMode, apply, "enter");

  let index = 0;
  return (
    <S.Root ref={ref} id="discover" tabIndex={-1} $static={staticMode}>
      <S.Stage $static={staticMode}>
        <S.Chips aria-hidden="true">
          {chips.map((chip, i) => (
            <span
              key={chip.label}
              style={
                {
                  "--i": i,
                  "--x": chip.x,
                  "--y": chip.y,
                  "--depth": chip.depth,
                  "--r": `${chip.r}deg`,
                } as CSSProperties
              }
            >
              <b>✳</b> {chip.label}
            </span>
          ))}
        </S.Chips>
        <CommonContainer>
          <S.Copy>
            <Eyebrow>Connection, with a little more feeling</Eyebrow>
            <h2 style={{ "--count": wordCount } as CSSProperties}>
              {heading.map((part, i) => {
                if (!part) return <br key={i} />;
                const style = { "--i": index++ } as CSSProperties;
                const word = (
                  <span key={i} style={style}>
                    {part.word}{" "}
                  </span>
                );
                return part.accent ? <em key={i}>{word}</em> : word;
              })}
            </h2>
            <p data-para>
              A shared song. A love of slow Sundays. The things that make you
              feel at home with someone new.
            </p>
            <p data-note>
              less searching for perfect. more finding your people.
            </p>
          </S.Copy>
          <ScrollMore target="journey" destination="how a connection begins" />
        </CommonContainer>
        <S.Ticker aria-label="Shared interests">
          <div aria-hidden="true">
            {Array.from({ length: 4 }, (_, i) => (
              <span key={i}>
                {ticker.map((label) => (
                  <span key={label}>
                    <b>✳</b> {label}
                  </span>
                ))}
              </span>
            ))}
          </div>
        </S.Ticker>
      </S.Stage>
    </S.Root>
  );
}
