import { useRef } from "react";
import type { CSSProperties } from "react";
import {
  smooth,
  usePinnedProgress,
  useStaticScene,
} from "../../../../hooks/usePinnedScene";
import * as S from "./BeliefStatement.styles";

const lead = "Just2 is a place for connection built on";
const accent = "being yourself.";
const body =
  "Where shared interests, honest profiles, and a mutual yes turn a little curiosity into something real.".split(
    " ",
  );

const apply = (progress: number, el: HTMLElement) => {
  el.style.setProperty("--shrink", String(smooth(progress / 0.35)));
  el.style.setProperty("--reveal", String(smooth((progress - 0.3) / 0.6)));
  el.style.setProperty("--drift", String(progress));
};

/** Pinned statement: the lead line settles small, then the rest lights up word by word. */
export function BeliefStatement() {
  const ref = useRef<HTMLElement>(null);
  const staticMode = useStaticScene();
  usePinnedProgress(ref, !staticMode, apply);

  return (
    <S.Root ref={ref} $static={staticMode}>
      <S.Stage $static={staticMode}>
        <S.Float $at="heart" aria-hidden="true">
          ♥
        </S.Float>
        <S.Float $at="spark" aria-hidden="true">
          ✳
        </S.Float>
        <S.Float $at="smile" aria-hidden="true">
          ☺
        </S.Float>
        <S.Text>
          <span data-lead>{lead}</span>
          <em>{accent}</em>
          <span data-body style={{ "--count": body.length } as CSSProperties}>
            {body.map((word, i) => (
              <span key={i} style={{ "--i": i } as CSSProperties}>
                {word}{" "}
              </span>
            ))}
          </span>
        </S.Text>
      </S.Stage>
    </S.Root>
  );
}
