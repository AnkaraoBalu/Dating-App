import { useEffect, useRef, useState } from "react";
import type { PropsWithChildren } from "react";
import { useReducedMotion } from "../../hooks/useReducedMotion";
import { Root } from "./Reveal.styles";
export function Reveal({
  children,
  delay = 0,
}: PropsWithChildren<{ delay?: number }>) {
  const ref = useRef<HTMLDivElement>(null);
  const [shown, setShown] = useState(false);
  const reduced = useReducedMotion();
  useEffect(() => {
    if (reduced) return;
    const observer = new IntersectionObserver(
      (entries) => {
        if (entries.some((entry) => entry.isIntersecting)) {
          setShown(true);
          observer.disconnect();
        }
      },
      { threshold: 0.08 },
    );
    if (ref.current) observer.observe(ref.current);
    return () => observer.disconnect();
  }, [reduced]);
  return (
    <Root ref={ref} $shown={shown || reduced} $delay={delay}>
      {children}
    </Root>
  );
}
