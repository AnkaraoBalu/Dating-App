import type { MouseEvent } from "react";
import { Control, Row } from "./ScrollMore.styles";

type Props = { target: string; destination: string; onAdvance?: () => void };

export function ScrollMore({ target, destination, onAdvance }: Props) {
  const advance = (event: MouseEvent<HTMLAnchorElement>) => {
    if (event.metaKey || event.ctrlKey || event.shiftKey || event.altKey)
      return;
    const next = document.getElementById(target);
    if (!next && !onAdvance) return;
    event.preventDefault();
    if (onAdvance) return onAdvance();
    next?.scrollIntoView({
      behavior: matchMedia("(prefers-reduced-motion: reduce)").matches
        ? "instant"
        : "smooth",
      block: "start",
    });
    next?.focus({ preventScroll: true });
  };
  return (
    <Row>
      <Control
        href={`#${target}`}
        onClick={advance}
        aria-label={`Scroll for more: ${destination}`}
      >
        Scroll for more <span aria-hidden="true">↓</span>
      </Control>
    </Row>
  );
}
