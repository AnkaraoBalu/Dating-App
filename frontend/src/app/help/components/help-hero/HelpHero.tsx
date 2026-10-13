import { useEffect, useState } from "react";
import type { CSSProperties } from "react";
import { CommonContainer } from "../../../../components";
import { Eyebrow, TextLink } from "../../../../components/ui";
import { useReducedMotion } from "../../../../hooks/useReducedMotion";
import { popular, questions } from "../../data/questions";
import * as S from "./HelpHero.styles";

const suggestions = [
  "Why do messages disappear?",
  "How does a match happen?",
  "Save in Chat",
  "Create a Vibe room",
  "Change my photos",
];

/** Types out example searches one character at a time while the field is empty and unfocused. */
function useTypedPlaceholder(active: boolean) {
  const [text, setText] = useState(suggestions[0]);
  useEffect(() => {
    if (!active) return;
    let item = 0;
    let chars = 0;
    let deleting = false;
    let timer = 0;
    const tick = () => {
      const word = suggestions[item];
      if (!deleting) {
        chars++;
        if (chars === word.length) deleting = true;
      } else {
        chars--;
        if (chars === 0) {
          deleting = false;
          item = (item + 1) % suggestions.length;
        }
      }
      setText(suggestions[item].slice(0, Math.max(chars, 0)) || "");
      const pause = !deleting ? 70 : chars === word.length - 1 ? 1600 : 30;
      timer = window.setTimeout(tick, pause);
    };
    timer = window.setTimeout(tick, 600);
    return () => clearTimeout(timer);
  }, [active]);
  return active ? text : suggestions[0];
}

export function HelpHero({
  query,
  onQuery,
  onSubmit,
  onPopular,
}: {
  query: string;
  onQuery: (value: string) => void;
  onSubmit: () => void;
  onPopular: (id: string) => void;
}) {
  const [focused, setFocused] = useState(false);
  const reduced = useReducedMotion();
  const placeholder = useTypedPlaceholder(!reduced && !focused && !query);

  return (
    <S.Root>
      <S.Marks aria-hidden="true">
        {["?", "✳", "♡", "?", "💬", "?"].map((mark, i) => (
          <span key={i} style={{ "--i": i } as CSSProperties}>
            {mark}
          </span>
        ))}
      </S.Marks>
      <CommonContainer>
        <S.Content>
          <Eyebrow>A little clarity</Eyebrow>
          <h1>
            How can we <em>help?</em>
          </h1>
          <S.Search
            role="search"
            onSubmit={(event) => {
              event.preventDefault();
              onSubmit();
            }}
          >
            <label htmlFor="help-search">Search the help center</label>
            <span aria-hidden="true">⌕</span>
            <input
              id="help-search"
              type="search"
              value={query}
              autoComplete="off"
              placeholder={placeholder}
              onFocus={() => setFocused(true)}
              onBlur={() => setFocused(false)}
              onChange={(event) => onQuery(event.target.value)}
            />
            <button type="submit">Search</button>
          </S.Search>
          <S.Popular>
            <span>Popular:</span>
            {popular.map((id, i) => {
              const q = questions.find((item) => item.id === id);
              return (
                q && (
                  <button
                    key={id}
                    style={{ "--i": i } as CSSProperties}
                    onClick={() => onPopular(id)}
                  >
                    {q.question}
                  </button>
                )
              );
            })}
          </S.Popular>
          <S.Contact>
            Can’t find what you need?{" "}
            <TextLink to="/support">Contact support →</TextLink>
          </S.Contact>
        </S.Content>
      </CommonContainer>
    </S.Root>
  );
}
