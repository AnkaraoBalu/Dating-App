import { useLayoutEffect, useRef, useState } from "react";
import type { CSSProperties, PointerEvent } from "react";
import { Link } from "react-router-dom";
import { CommonContainer } from "../../../../components";
import { Eyebrow, Heading } from "../../../../components/ui";
import { Reveal } from "../../../../components/reveal";
import { useReducedMotion } from "../../../../hooks/useReducedMotion";
import { vibeGroups, vibes } from "../../data/vibes";
import * as S from "./RoomsExplorer.styles";

const others = ["maya", "leo", "zoe", "noah", "aarav", "leah"];

/** Filterable room cards: a sliding tab highlight, cards that tilt toward the cursor and preview a message. */
export function RoomsExplorer() {
  const [group, setGroup] = useState<(typeof vibeGroups)[number]>("All vibes");
  const tabs = useRef<HTMLDivElement>(null);
  const reduced = useReducedMotion();
  const shown = vibes.filter((v) => group === "All vibes" || v.group === group);

  // Slide the highlight under the active tab.
  useLayoutEffect(() => {
    const host = tabs.current;
    const place = () => {
      const active = host?.querySelector<HTMLElement>('[aria-pressed="true"]');
      if (!host || !active) return;
      host.style.setProperty("--pill-x", `${active.offsetLeft}px`);
      host.style.setProperty("--pill-w", `${active.offsetWidth}px`);
    };
    place();
    addEventListener("resize", place);
    return () => removeEventListener("resize", place);
  }, [group]);

  const tilt = (event: PointerEvent<HTMLElement>) => {
    if (reduced || event.pointerType !== "mouse") return;
    const card = event.currentTarget;
    const rect = card.getBoundingClientRect();
    card.style.setProperty(
      "--tx",
      String((event.clientX - rect.left) / rect.width - 0.5),
    );
    card.style.setProperty(
      "--ty",
      String((event.clientY - rect.top) / rect.height - 0.5),
    );
  };
  const untilt = (event: PointerEvent<HTMLElement>) => {
    event.currentTarget.style.setProperty("--tx", "0");
    event.currentTarget.style.setProperty("--ty", "0");
  };

  return (
    <S.Root id="rooms">
      <CommonContainer>
        <Reveal>
          <S.Intro>
            <Eyebrow>Rooms that match your energy</Eyebrow>
            <Heading>
              Pick a room.
              <br />
              <em>Say hello.</em>
            </Heading>
          </S.Intro>
        </Reveal>
        <S.Tabs ref={tabs} role="group" aria-label="Filter vibe rooms">
          <span data-pill aria-hidden="true" />
          {vibeGroups.map((g) => (
            <button
              key={g}
              aria-pressed={group === g}
              onClick={() => setGroup(g)}
            >
              {g}
            </button>
          ))}
        </S.Tabs>
        <S.Grid key={group} aria-live="polite">
          {shown.map((vibe, i) => (
            <S.Card
              key={vibe.id}
              style={{ "--i": i } as CSSProperties}
              onPointerMove={tilt}
              onPointerLeave={untilt}
            >
              <Link to="/download">
                <div data-photo>
                  <img
                    src={vibe.cover}
                    alt=""
                    loading="lazy"
                  />
                  <span data-emoji aria-hidden="true">
                    {vibe.emoji}
                  </span>
                  <div data-preview>
                    <img
                      src={`/images/${others[(i + 2) % others.length]}.png`}
                      alt=""
                    />
                    <p>{vibe.message}</p>
                  </div>
                </div>
                <div data-content>
                  <div data-group>{vibe.group}</div>
                  <h2>{vibe.title}</h2>
                  <p>{vibe.description}</p>
                  <div data-foot>
                    <span data-faces aria-hidden="true">
                      {[0, 1, 2].map((k) => (
                        <img
                          key={k}
                          src={`/images/${others[(i + k) % others.length]}.png`}
                          alt=""
                        />
                      ))}
                    </span>
                    <span data-join>Join in the app ↗</span>
                  </div>
                </div>
              </Link>
            </S.Card>
          ))}
        </S.Grid>
        <S.Note>
          Illustrative previews. Live rooms and the people in them are shown
          inside the app.
        </S.Note>
      </CommonContainer>
    </S.Root>
  );
}
