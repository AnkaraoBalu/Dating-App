import { useRef } from "react";
import { CommonContainer } from "../../../../components";
import { ScrollMore } from "../../../../components/scroll-more";
import {
  Actions,
  ButtonLink,
  Eyebrow,
  TextLink,
} from "../../../../components/ui";
import {
  smooth,
  usePinnedProgress,
  useStaticScene,
} from "../../../../hooks/usePinnedScene";
import * as S from "./HomeHero.styles";

const apply = (progress: number, el: HTMLElement) => {
  el.style.setProperty("--meet", String(smooth(progress / 0.6)));
  el.style.setProperty("--pop", String(smooth((progress - 0.45) / 0.35)));
};

/** Pinned hero: the two photos drift together and the heart lands between them. */
export function HomeHero() {
  const ref = useRef<HTMLElement>(null);
  const staticMode = useStaticScene();
  usePinnedProgress(ref, !staticMode, apply);

  return (
    <S.Root ref={ref} id="welcome" tabIndex={-1} $static={staticMode}>
      <S.Stage $static={staticMode}>
        <CommonContainer>
          <S.Hero>
            <div>
              <Eyebrow>Less small talk. More possibility.</Eyebrow>
              <h1>
                Less swiping.
                <br />
                More vibing.
                <br />
                <em>Real connections.</em>
              </h1>
              <p data-copy>
                Meet people who match your energy. From late-night conversations
                to shared interests and spontaneous plans, find connections that
                actually feel right.
              </p>
              <Actions data-actions>
                <ButtonLink to="/download">Meet Matchify ↗</ButtonLink>
                <TextLink to="/how-it-works">
                  How it works <span>→</span>
                </TextLink>
              </Actions>
            </div>
            <S.Art aria-label="Illustrative Matchify profiles">
              <S.Photo $side="left">
                <img
                  src="/images/maya.png"
                  alt="Illustrative portrait in golden evening light"
                  fetchPriority="high"
                />
                <figcaption>here for the little things</figcaption>
              </S.Photo>
              <S.Photo $side="right">
                <img
                  src="/images/aarav.png"
                  alt="Illustrative portrait at a café"
                  fetchPriority="high"
                />
                <figcaption>coffee & good company</figcaption>
              </S.Photo>
              <S.Heart aria-hidden="true">♡</S.Heart>
              <S.Sticker>
                <strong>Same vibe. New story.</strong>Something in common is a
                lovely start.
              </S.Sticker>
              <S.Handwritten aria-hidden="true">
                <span data-before>what if it starts here? ↗</span>
                <span data-after>it starts here ♡</span>
              </S.Handwritten>
            </S.Art>
          </S.Hero>
          <S.ScrollHint>
            <span>A little curiosity goes a long way</span>
            <ScrollMore target="discover" destination="discover Matchify" />
          </S.ScrollHint>
        </CommonContainer>
      </S.Stage>
    </S.Root>
  );
}
