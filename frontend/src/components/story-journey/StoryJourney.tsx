import { useRef, useState } from "react";
import type { CSSProperties } from "react";
import { ScrollMore } from "../scroll-more";
import { CommonContainer } from "../common-container";
import { Eyebrow } from "../ui";
import {
  smooth,
  usePinnedProgress,
  useStaticScene,
} from "../../hooks/usePinnedScene";
import * as S from "./StoryJourney.styles";

const steps = [
  {
    title: "A profile that feels like",
    accent: "you.",
    body: "The photos, prompts, and interests that tell your story. Give someone a reason to be curious beyond a first impression.",
    image: "maya",
    tag: "01 / A little more you",
  },
  {
    title: "Find your kind of",
    accent: "common ground.",
    body: "Explore people through Discover. Follow an interest into Vibes. There is more than one way to start a connection.",
    image: "leo",
    tag: "02 / Follow your curiosity",
  },
  {
    title: "A mutual yes. A new",
    accent: "beginning.",
    body: "When you both like each other, it’s a match. Start with a hello, share a photo, and let the conversation find its own pace.",
    image: "aarav",
    tag: "03 / Make the first hello",
  },
];
const count = steps.length;

/** How present step `i` is at overall progress `p` (1 = fully shown) and which side it is on. */
const presence = (p: number, i: number) => {
  const at = p * count - (i + 0.5);
  const edge =
    (i === 0 && at < 0) || (i === count - 1 && at > 0) ? 0 : Math.abs(at);
  const shown = Math.max(0, Math.min(1, 1 - (edge - 0.3) / 0.2));
  return { shown, side: Math.sign(at) };
};

/**
 * Pinned walkthrough: steps crossfade as you scroll, the portrait dissolves
 * between people and the progress bar fills continuously.
 */
export function StoryJourney({ nextTarget }: { nextTarget?: string }) {
  const ref = useRef<HTMLElement>(null);
  const [active, setActive] = useState(0);
  const staticMode = useStaticScene();

  usePinnedProgress(ref, !staticMode, (p, el) => {
    el.style.setProperty("--p", String(p));
    // Number reel rolls only around each hand-over, not continuously.
    const x = Math.max(0, Math.min(count - 1, p * count - 0.5));
    const base = Math.floor(x);
    el.style.setProperty(
      "--reel",
      String(Math.min(count - 1, base + smooth((x - base - 0.3) / 0.4))),
    );
    el.querySelectorAll<HTMLElement>("[data-step]").forEach((node) => {
      const { shown, side } = presence(p, Number(node.dataset.step));
      node.style.setProperty("--shown", String(shown));
      node.style.setProperty("--side", String(side));
      // Portraits: each new one wipes up over the previous around the hand-over.
      const i = Number(node.dataset.step);
      node.style.setProperty(
        "--wipe",
        String(i === 0 ? 1 : smooth((p * count - i + 0.3) / 0.6)),
      );
    });
    setActive(Math.min(count - 1, Math.floor(p * count)));
  });

  // Scroll so that step `index` is fully shown (first at the start, last at the end).
  const go = (index: number) => {
    const el = ref.current;
    if (el)
      window.scrollTo({
        top:
          scrollY +
          el.getBoundingClientRect().top +
          (el.offsetHeight - innerHeight) * (index / (count - 1)),
        behavior: "smooth",
      });
  };

  return (
    <S.Root ref={ref} $static={staticMode} id="journey" tabIndex={-1}>
      <S.Stage $static={staticMode}>
        <CommonContainer>
          {staticMode ? (
            <>
              <Eyebrow>Three little steps. So much possibility.</Eyebrow>
              {steps.map((s, i) => (
                <S.StaticStep key={s.title}>
                  <span>0{i + 1}</span>
                  <h3>
                    {s.title} {s.accent}
                  </h3>
                  <p>{s.body}</p>
                </S.StaticStep>
              ))}
            </>
          ) : (
            <S.Content>
              <div>
                <Eyebrow>
                  How a connection begins /{" "}
                  <S.Reel aria-hidden="true">
                    <span>
                      {steps.map((_, i) => (
                        <span key={i}>0{i + 1}</span>
                      ))}
                    </span>
                  </S.Reel>
                  <S.VisuallyHidden>
                    step {active + 1} of {count}
                  </S.VisuallyHidden>
                </Eyebrow>
                <S.Texts>
                  {steps.map((s, i) => (
                    <div key={s.title} data-step={i} aria-hidden={i !== active}>
                      <h2>
                        {s.title} <em>{s.accent}</em>
                      </h2>
                      <p>{s.body}</p>
                    </div>
                  ))}
                </S.Texts>
                <S.Progress aria-label="Walkthrough steps">
                  {steps.map((s, i) => (
                    <button
                      key={s.title}
                      aria-label={`Step ${i + 1}: ${s.title} ${s.accent}`}
                      aria-current={i === active}
                      style={{ "--i": i } as CSSProperties}
                      onClick={() => go(i)}
                    />
                  ))}
                </S.Progress>
              </div>
              <S.Portrait>
                {steps.map((s, i) => (
                  <figure
                    key={s.image}
                    data-step={i}
                    aria-hidden={i !== active}
                  >
                    <img
                      src={`/images/${s.image}.png`}
                      alt="Illustrative Just2 profile"
                      loading="lazy"
                    />
                    <span>{s.tag}</span>
                  </figure>
                ))}
              </S.Portrait>
            </S.Content>
          )}
          {(!staticMode || nextTarget) && (
            <ScrollMore
              target={nextTarget ?? "journey"}
              destination={
                !staticMode && active < count - 1
                  ? `walkthrough step ${active + 2}`
                  : "the next section"
              }
              onAdvance={
                !staticMode && active < count - 1
                  ? () => go(active + 1)
                  : undefined
              }
            />
          )}
        </CommonContainer>
      </S.Stage>
    </S.Root>
  );
}
