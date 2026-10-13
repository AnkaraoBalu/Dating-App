import { useRef } from "react";
import type { CSSProperties, ReactNode } from "react";
import { Eyebrow } from "../../../../components/ui";
import {
  usePinnedProgress,
  useStaticScene,
} from "../../../../hooks/usePinnedScene";
import { icebreakers } from "../../data/vibes";
import * as S from "./InsideRoom.styles";

const panels: { title: string; body: string; visual: ReactNode }[] = [
  {
    title: "Drop into a room and say hello",
    body: "Join a room around something you love and jump into the conversation. The topic is already your opener.",
    visual: (
      <S.Chat>
        <header>
          <b>🎵</b> Music &amp; Chill
        </header>
        {[
          ["leo", "Drop the last song you had on repeat 🎧"],
          ["leah", "Okay this one has been living in my head all week"],
          ["aarav", "Wait, I love them. Seen them live?"],
        ].map(([face, text], k) => (
          <p key={k} style={{ "--k": k } as CSSProperties}>
            <img src={`/images/${face}.png`} alt="" />
            <span>{text}</span>
          </p>
        ))}
      </S.Chat>
    ),
  },
  {
    title: "Break the ice ✨",
    body: "Play a quick game together. A little fun makes every connection easier.",
    visual: (
      <S.Games>
        <div data-chips>
          {icebreakers.map((game, k) => (
            <span key={game} style={{ "--k": k } as CSSProperties}>
              {game}
            </span>
          ))}
        </div>
        <div data-poll>
          <strong>Would You Rather?</strong>
          <div data-round>Where would you escape for the weekend?</div>
          <div data-choices>
            <div data-choice style={{ "--v": 0.64 } as CSSProperties}>
              <img src="/images/vibes/beach_getaway.jpg" alt="" />
              <span>Beach getaway</span>
              <i />
            </div>
            <div data-choice style={{ "--v": 0.36 } as CSSProperties}>
              <img src="/images/vibes/mountain_travel.jpg" alt="" />
              <span>Mountain escape</span>
              <i />
            </div>
          </div>
          <div data-round>This or That: a cozy night in?</div>
          <div data-choices>
            <div data-choice style={{ "--v": 0.64 } as CSSProperties}>
              <img src="/images/vibes/board_games.jpg" alt="" />
              <span>Board game night</span>
              <i />
            </div>
            <div data-choice style={{ "--v": 0.36 } as CSSProperties}>
              <img src="/images/vibes/movie_night.jpg" alt="" />
              <span>Movie night</span>
              <i />
            </div>
          </div>
        </div>
      </S.Games>
    ),
  },
  {
    title: "Go live, out loud",
    body: "Hop into a live voice room when typing isn’t enough. Hear the laugh behind the message.",
    visual: (
      <S.Voice>
        <span data-live>
          <i /> Live right now
        </span>
        <div data-speakers>
          {["maya", "noah", "zoe", "leo"].map((face, k) => (
            <span key={face} data-speaking={k === 0}>
              <img src={`/images/${face}.png`} alt="" />
            </span>
          ))}
        </div>
        <div data-wave aria-hidden="true">
          {Array.from({ length: 18 }, (_, k) => (
            <i key={k} style={{ "--k": k } as CSSProperties} />
          ))}
        </div>
      </S.Voice>
    ),
  },
  {
    title: "Start your own",
    body: "Can’t find your vibe? Create a room, set the mood, and save the ones you love for later.",
    visual: (
      <S.Create>
        <strong>Create a room</strong>
        <div data-emojis>
          {["☕", "🌙", "🎵", "🍜", "✈️", "✨"].map((e, k) => (
            <span key={e} data-picked={k === 2}>
              {e}
            </span>
          ))}
        </div>
        <div data-field>
          <span>Sunday Sketch &amp; Playlist Club</span>
        </div>
        <div data-actions>
          <span data-save>♡ Save</span>
          <span data-go>Create room</span>
        </div>
      </S.Create>
    ),
  },
];
const count = panels.length;

/** Pinned sideways tour of what happens inside a Vibe room. */
export function InsideRoom() {
  const ref = useRef<HTMLElement>(null);
  const staticMode = useStaticScene();

  usePinnedProgress(ref, !staticMode, (p, el) => {
    const track = el.querySelector<HTMLElement>("[data-track]");
    if (!track) return;
    el.style.setProperty("--p", String(p));
    el.style.setProperty(
      "--shift",
      `${-p * (track.scrollWidth - innerWidth)}px`,
    );
    track.querySelectorAll<HTMLElement>("[data-panel]").forEach((panel, i) => {
      const seen = 1 - Math.min(1, Math.abs(p * (count - 1) - i));
      panel.style.setProperty("--seen", seen.toFixed(3));
    });
  });

  return (
    <S.Root ref={ref} $static={staticMode}>
      <S.Stage $static={staticMode}>
        <S.Head>
          <Eyebrow>Inside a vibe room</Eyebrow>
          <S.Bar aria-hidden="true">
            <i />
          </S.Bar>
        </S.Head>
        <S.Track data-track $static={staticMode}>
          {panels.map((panel, i) => (
            <S.Panel key={panel.title} data-panel>
              <div data-text>
                <span data-num>0{i + 1}</span>
                <h2>{panel.title}</h2>
                <p>{panel.body}</p>
              </div>
              <div data-visual>{panel.visual}</div>
            </S.Panel>
          ))}
        </S.Track>
      </S.Stage>
    </S.Root>
  );
}
