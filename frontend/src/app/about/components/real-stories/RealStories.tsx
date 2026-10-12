import { useRef } from "react";
import { CircularCarousel } from "../../../../components/circular-carousel";
import { Reveal } from "../../../../components/reveal";
import {
  smooth,
  usePinnedProgress,
  useStaticScene,
} from "../../../../hooks/usePinnedScene";
import * as S from "./RealStories.styles";

// Illustrative stories: swap in real member stories (shared with permission) when available.
const stories = [
  {
    image: "maya",
    name: "Maya, 27",
    place: "Bengaluru",
    tag: "Matched in Vibes",
    quote: "We bonded over one song.",
    body: "A shared playlist in a Vibe room turned into a three-hour conversation. We still argue about the best track.",
  },
  {
    image: "aarav",
    name: "Aarav, 29",
    place: "Hyderabad",
    tag: "Dater",
    quote: "It felt less like swiping.",
    body: "Prompts gave me something real to reply to. Our first message was about chai, not small talk.",
  },
  {
    image: "leah",
    name: "Leah, 25",
    place: "Pune",
    tag: "Matched",
    quote: "We saved the message that started it.",
    body: "Viewed messages disappear, so we saved the one where it all clicked. It’s still there for both of us.",
  },
  {
    image: "leo",
    name: "Leo, 28",
    place: "Chennai",
    tag: "Vibes regular",
    quote: "I found my weekend crew.",
    body: "I came for dates and found people who love trekking as much as I do. The match came later.",
  },
  {
    image: "zoe",
    name: "Zoe, 26",
    place: "Mumbai",
    tag: "Matched",
    quote: "A mutual yes takes the pressure off.",
    body: "Knowing we both liked each other made the first hello so much easier.",
  },
  {
    image: "noah",
    name: "Noah, 30",
    place: "Delhi",
    tag: "Dater",
    quote: "Real people, real pace.",
    body: "No rush, no games. We talked for a week before meeting, and it felt right.",
  },
];

const apply = (progress: number, el: HTMLElement) => {
  const enter = smooth(progress / 0.6);
  el.style.setProperty("--enter", String(enter));
  el.style.setProperty("--spin", `${(1 - enter) * 120}deg`);
};

/** Member stories on a 3D ring that spins into place as the section scrolls in. */
export function RealStories() {
  const ref = useRef<HTMLElement>(null);
  const staticMode = useStaticScene();
  usePinnedProgress(ref, !staticMode, apply, "enter");

  return (
    <S.Root ref={ref}>
      <Reveal>
        <S.Heading>
          Real people.
          <br />
          <em>Real stories.</em>
        </S.Heading>
      </Reveal>
      <S.Ring>
        <CircularCarousel
          label="Member stories"
          items={stories.map((story) => ({
            key: story.image,
            label: `${story.name}: ${story.quote}`,
            content: (
              <S.Story>
                <img src={`/images/${story.image}.png`} alt="" loading="lazy" />
                <strong>{story.name}</strong>
                <small>{story.place}</small>
                <span data-tag>{story.tag}</span>
                <h3>“{story.quote}”</h3>
                <p>{story.body}</p>
              </S.Story>
            ),
          }))}
        />
      </S.Ring>
      <S.Caption>
        Illustrative stories · drag, tap a card, or use the arrows
      </S.Caption>
    </S.Root>
  );
}
