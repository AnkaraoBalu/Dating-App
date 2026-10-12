import { useEffect, useState } from "react";
import type { RefObject } from "react";

const staticQuery =
  "(max-width:850px), (max-height:700px), (prefers-reduced-motion:reduce)";

/** True on small screens or reduced motion, where pinned scenes render as plain sections. */
export function useStaticScene() {
  const [staticMode, setStatic] = useState(
    () => matchMedia(staticQuery).matches,
  );
  useEffect(() => {
    const media = matchMedia(staticQuery);
    const update = () => setStatic(media.matches);
    media.addEventListener("change", update);
    return () => media.removeEventListener("change", update);
  }, []);
  return staticMode;
}

export const smooth = (x: number) => {
  const t = Math.max(0, Math.min(1, x));
  return t * t * (3 - 2 * t);
};

/**
 * Reports how far a tall section has been scrolled through its pinned stage
 * (0 = stage just pinned, 1 = about to release). With `from: "enter"`, 0 is
 * when the section's top first appears at the bottom of the viewport, so the
 * animation is already under way by the time the stage pins. Writes no React
 * state, so `apply` should set CSS custom properties on the element.
 */
export function usePinnedProgress(
  ref: RefObject<HTMLElement | null>,
  enabled: boolean,
  apply: (progress: number, el: HTMLElement) => void,
  from: "pin" | "enter" = "pin",
) {
  useEffect(() => {
    if (!enabled) return;
    let frame = 0;
    const update = () => {
      frame = 0;
      const el = ref.current;
      if (!el) return;
      const top = el.getBoundingClientRect().top;
      const progress = Math.max(
        0,
        Math.min(
          1,
          from === "enter"
            ? (innerHeight - top) / el.offsetHeight
            : -top / (el.offsetHeight - innerHeight),
        ),
      );
      apply(progress, el);
    };
    const scroll = () => {
      if (!frame) frame = requestAnimationFrame(update);
    };
    update();
    addEventListener("scroll", scroll, { passive: true });
    addEventListener("resize", scroll);
    return () => {
      removeEventListener("scroll", scroll);
      removeEventListener("resize", scroll);
      cancelAnimationFrame(frame);
    };
    // `apply` is expected to be a stable module-level function.
  }, [enabled, ref, from]);
}
