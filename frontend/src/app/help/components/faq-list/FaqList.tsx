import { useLayoutEffect, useRef } from "react";
import type { CSSProperties, ReactNode } from "react";
import { CommonContainer } from "../../../../components";
import { Eyebrow, Heading } from "../../../../components/ui";
import { questions, topics } from "../../data/questions";
import type { Category } from "../../HelpPage";
import * as S from "./FaqList.styles";

const categories: Category[] = ["All questions", ...topics.map((t) => t.name)];

/** Wraps every occurrence of `term` in a <mark>. */
function highlight(text: string, term: string): ReactNode {
  if (!term) return text;
  const lower = text.toLowerCase();
  const parts: ReactNode[] = [];
  let from = 0;
  for (
    let at = lower.indexOf(term);
    at !== -1;
    at = lower.indexOf(term, from)
  ) {
    parts.push(
      text.slice(from, at),
      <mark key={at}>{text.slice(at, at + term.length)}</mark>,
    );
    from = at + term.length;
  }
  parts.push(text.slice(from));
  return parts;
}

export function FaqList({
  shown,
  term,
  category,
  onCategory,
  open,
  onToggle,
  onClear,
}: {
  shown: (typeof questions)[number][];
  term: string;
  category: Category;
  onCategory: (c: Category) => void;
  open: string | null;
  onToggle: (id: string) => void;
  onClear: () => void;
}) {
  const tabs = useRef<HTMLDivElement>(null);

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
  }, [category]);

  return (
    <S.Root id="answers">
      <CommonContainer>
        <S.Head>
          <div>
            <Eyebrow>Good questions</Eyebrow>
            <Heading>
              Simple <em>answers.</em>
            </Heading>
          </div>
          <S.Count aria-live="polite">
            {term ? (
              <>
                {shown.length} {shown.length === 1 ? "result" : "results"} for “
                {term}”
              </>
            ) : (
              <>
                {shown.length} {shown.length === 1 ? "answer" : "answers"}
              </>
            )}
          </S.Count>
        </S.Head>
        <S.Tabs ref={tabs} role="group" aria-label="Help categories">
          <span data-pill aria-hidden="true" />
          {categories.map((c) => (
            <button
              key={c}
              aria-pressed={category === c}
              onClick={() => onCategory(c)}
            >
              {c}
            </button>
          ))}
        </S.Tabs>
        <S.List key={`${category}|${term}`}>
          {shown.map((q, i) => {
            const isOpen = open === q.id || (!!term && shown.length <= 2);
            return (
              <S.Item
                key={q.id}
                id={q.id}
                data-open={isOpen}
                style={{ "--i": i } as CSSProperties}
              >
                <h3>
                  <button
                    aria-expanded={isOpen}
                    aria-controls={`${q.id}-answer`}
                    onClick={() => onToggle(q.id)}
                  >
                    <span data-topic>{q.category}</span>
                    <span data-q>{highlight(q.question, term)}</span>
                    <span data-icon aria-hidden="true" />
                  </button>
                </h3>
                <div id={`${q.id}-answer`} data-answer role="region">
                  <div>
                    <p>{highlight(q.answer, term)}</p>
                  </div>
                </div>
              </S.Item>
            );
          })}
          {shown.length === 0 && (
            <S.Empty>
              <span aria-hidden="true">🔍</span>
              <h3>No answers found just yet.</h3>
              <p>Try a shorter search or browse all questions.</p>
              <button onClick={onClear}>Clear search</button>
            </S.Empty>
          )}
        </S.List>
      </CommonContainer>
    </S.Root>
  );
}
