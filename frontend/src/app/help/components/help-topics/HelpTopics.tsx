import type { CSSProperties } from "react";
import { CommonContainer } from "../../../../components";
import { Reveal } from "../../../../components/reveal";
import { questions, topics } from "../../data/questions";
import * as S from "./HelpTopics.styles";

/** Browse-by-topic cards; picking one filters the answers below and scrolls to them. */
export function HelpTopics({
  onPick,
}: {
  onPick: (topic: (typeof topics)[number]["name"]) => void;
}) {
  return (
    <S.Root>
      <CommonContainer>
        <S.Grid>
          {topics.map((topic, i) => {
            const count = questions.filter(
              (q) => q.category === topic.name,
            ).length;
            return (
              <Reveal key={topic.name} delay={i * 0.08}>
                <S.Card
                  style={{ "--i": i } as CSSProperties}
                  onClick={() => onPick(topic.name)}
                >
                  <span data-emoji aria-hidden="true">
                    {topic.emoji}
                  </span>
                  <strong>{topic.name}</strong>
                  <p>{topic.blurb}</p>
                  <span data-count>
                    {count} {count === 1 ? "answer" : "answers"} <b>→</b>
                  </span>
                </S.Card>
              </Reveal>
            );
          })}
        </S.Grid>
      </CommonContainer>
    </S.Root>
  );
}
