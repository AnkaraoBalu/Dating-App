import { useEffect, useRef, useState } from "react";
import type { CSSProperties } from "react";
import { useReducedMotion } from "../../hooks/useReducedMotion";
import * as S from "./IntroSplash.styles";

const HOLD = 1100; // ms the big logo sits centred before flying
const FLY = 850; // ms for the flight into the navbar

/**
 * First-load intro: the logo appears big in the centre of a cream screen, then
 * flies into its place in the navbar while the page fades in underneath.
 * Runs once per page load (not on in-app navigation). Click or press a key to skip.
 */
export function IntroSplash() {
  const reduced = useReducedMotion();
  const [phase, setPhase] = useState<"show" | "fly" | "done">(
    reduced ? "done" : "show",
  );
  const logo = useRef<HTMLDivElement>(null);
  const root = document.documentElement;

  // While the intro runs, hide the real navbar logo and lock scrolling.
  useEffect(() => {
    if (phase === "done") {
      delete root.dataset.intro;
      return;
    }
    root.dataset.intro = phase;
  }, [phase, root]);

  useEffect(() => {
    if (phase !== "show") return;
    const timer = window.setTimeout(() => setPhase("fly"), HOLD);
    const skip = () => setPhase("fly");
    addEventListener("pointerdown", skip, { once: true });
    addEventListener("keydown", skip, { once: true });
    return () => {
      clearTimeout(timer);
      removeEventListener("pointerdown", skip);
      removeEventListener("keydown", skip);
    };
  }, [phase]);

  // Fly: move and scale the big logo onto the navbar logo's exact box.
  useEffect(() => {
    if (phase !== "fly") return;
    const el = logo.current;
    const target = document.querySelector<HTMLElement>(
      'header a[aria-label="Matchify home"]',
    );
    if (!el || !target) return setPhase("done");
    const from = el.getBoundingClientRect();
    const to = target.getBoundingClientRect();
    const scale = to.width / from.width;
    const dx = to.left + to.width / 2 - (from.left + from.width / 2);
    const dy = to.top + to.height / 2 - (from.top + from.height / 2);
    el.style.transform = `translate(${dx}px, ${dy}px) scale(${scale})`;
    const timer = window.setTimeout(() => setPhase("done"), FLY + 50);
    return () => clearTimeout(timer);
  }, [phase]);

  if (phase === "done") return null;
  return (
    <>
      <S.IntroGlobal />
      <S.Overlay
        data-phase={phase}
        aria-hidden="true"
        style={{ "--fly": `${FLY}ms` } as CSSProperties}
      >
        <S.Logo ref={logo}>
          matchify<span>✳</span>
        </S.Logo>
      </S.Overlay>
    </>
  );
}
