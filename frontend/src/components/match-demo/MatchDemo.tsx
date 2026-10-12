import { useState } from "react";
import type { CSSProperties } from "react";
import * as S from "./MatchDemo.styles";

const pairs = [
  ["maya", "aarav"],
  ["leah", "leo"],
  ["zoe", "noah"],
];

/**
 * Interactive match: the first "yes" is already there; liking back makes it mutual.
 * A parent may drive `--meet` (cards slide together) and `--first` (first stamp) on scroll.
 */
export function MatchDemo() {
  const [index, setIndex] = useState(0);
  const [matched, setMatched] = useState(false);
  const [left, right] = pairs[index];
  const next = () => {
    setIndex((index + 1) % pairs.length);
    setMatched(false);
  };
  return (
    <S.Demo>
      <S.Pair key={index} data-matched={matched}>
        <figure data-side="left">
          <img
            src={`/images/${left}.png`}
            alt="Illustrative profile one"
            loading="lazy"
          />
          <span data-stamp>♡ liked you</span>
        </figure>
        <figure data-side="right">
          <img
            src={`/images/${right}.png`}
            alt="Illustrative profile two"
            loading="lazy"
          />
          <span data-stamp>♡ liked back</span>
        </figure>
        <S.Heart aria-hidden="true">
          ♡
          {Array.from({ length: 8 }, (_, i) => (
            <i key={i} style={{ "--a": `${i * 45}deg` } as CSSProperties}>
              ♥
            </i>
          ))}
        </S.Heart>
      </S.Pair>
      <S.Controls>
        {matched ? (
          <button onClick={next}>Try another pair →</button>
        ) : (
          <button data-primary onClick={() => setMatched(true)}>
            Like back ♡
          </button>
        )}
      </S.Controls>
      <S.Status aria-live="polite">
        {matched
          ? "You both said yes. Now the conversation can begin."
          : "One yes so far. A match needs two."}
      </S.Status>
      <S.Caption>Illustrative preview · no real profiles or likes</S.Caption>
    </S.Demo>
  );
}
