import { useRef } from "react";
import { PageHero } from "../../../../components/page-hero";
import { CommonContainer } from "../../../../components";
import { Eyebrow } from "../../../../components/ui";
import {
  smooth,
  usePinnedProgress,
  useStaticScene,
} from "../../../../hooks/usePinnedScene";
import * as S from "./StoryHero.styles";

const eyebrow = "Our story";
const description =
  "We’re making room for the details that make a connection feel real. The interests, the energy, the conversations you don’t want to end.";
const photos = {
  center: ["leah", "Illustrative music lover"],
  left: ["aarav", "Illustrative café conversation"],
  right: ["zoe", "Illustrative coffee enthusiast"],
} as const;

const apply = (progress: number, el: HTMLElement) => {
  el.style.setProperty("--open", String(smooth(progress / 0.45)));
  el.style.setProperty("--grow", String(smooth((progress - 0.45) / 0.45)));
};

/** Pinned hero: the headline parts, a photo grows between the lines, then the scene opens up. */
export function StoryHero() {
  const ref = useRef<HTMLElement>(null);
  const staticMode = useStaticScene();
  usePinnedProgress(ref, !staticMode, apply);

  if (staticMode)
    return (
      <>
        <PageHero
          eyebrow={eyebrow}
          title={
            <>
              A little less perfect.
              <br />
              <em>A little more human.</em>
            </>
          }
          description={description}
        />
        <CommonContainer>
          <S.PhotoRow aria-label="Illustrations of the Just2 community">
            {[photos.left, photos.center, photos.right].map(([image, alt]) => (
              <img key={image} src={`/images/${image}.png`} alt={alt} />
            ))}
          </S.PhotoRow>
        </CommonContainer>
      </>
    );

  return (
    <S.Root ref={ref}>
      <S.Stage>
        <S.Side $side="left">
          <img src={`/images/${photos.left[0]}.png`} alt={photos.left[1]} />
        </S.Side>
        <S.Side $side="right">
          <img src={`/images/${photos.right[0]}.png`} alt={photos.right[1]} />
        </S.Side>
        <S.Center>
          <img
            src={`/images/${photos.center[0]}.png`}
            alt={photos.center[1]}
            fetchPriority="high"
          />
        </S.Center>
        <S.Copy>
          <div data-up>
            <Eyebrow>{eyebrow}</Eyebrow>
          </div>
          <h1>
            <span data-up>A little less perfect.</span>
            <span data-down>
              <em>A little more human.</em>
            </span>
          </h1>
          <p data-down>{description}</p>
        </S.Copy>
      </S.Stage>
    </S.Root>
  );
}
