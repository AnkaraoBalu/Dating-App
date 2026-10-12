import { useRef } from "react";
import { CommonContainer } from "../../../../components";
import { MatchDemo } from "../../../../components/match-demo";
import { ScrollMore } from "../../../../components/scroll-more";
import { Copy, Eyebrow, Heading, TextLink } from "../../../../components/ui";
import {
  smooth,
  usePinnedProgress,
  useStaticScene,
} from "../../../../hooks/usePinnedScene";
import * as S from "./HomeMatch.styles";

const apply = (progress: number, el: HTMLElement) => {
  el.style.setProperty("--line-1", String(smooth((progress - 0.08) / 0.25)));
  el.style.setProperty("--line-2", String(smooth((progress - 0.2) / 0.25)));
  el.style.setProperty("--copy", String(smooth((progress - 0.32) / 0.22)));
  el.style.setProperty("--meet", String(smooth(progress / 0.55)));
  el.style.setProperty("--first", String(smooth((progress - 0.5) / 0.15)));
};

/** "Same spark": the cards slide together on scroll; the visitor makes the match mutual. */
export function HomeMatch() {
  const ref = useRef<HTMLElement>(null);
  const staticMode = useStaticScene();
  usePinnedProgress(ref, !staticMode, apply, "enter");

  return (
    <S.Root ref={ref} id="matching" tabIndex={-1} $static={staticMode}>
      <S.Stage $static={staticMode}>
        <CommonContainer>
          <S.Layout>
            <S.Text>
              <Eyebrow>A small yes can go a long way</Eyebrow>
              <Heading>
                <span data-line="1">Different stories.</span>
                <span data-line="2">
                  <em>Same spark.</em>
                </span>
              </Heading>
              <div data-copy>
                <Copy>
                  There’s something lovely about a mutual feeling. Someone
                  catches your eye, and when they like you back, you can start
                  talking. Try it: they’ve already said yes.
                </Copy>
                <S.Link>
                  <TextLink to="/how-it-works">
                    See how connections happen →
                  </TextLink>
                </S.Link>
              </div>
            </S.Text>
            <MatchDemo />
          </S.Layout>
          <ScrollMore target="conversations" destination="conversations" />
        </CommonContainer>
      </S.Stage>
    </S.Root>
  );
}
