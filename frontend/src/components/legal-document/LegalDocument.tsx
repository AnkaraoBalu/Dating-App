import { useEffect, useRef, useState } from "react";
import { Link } from "react-router-dom";
import { CommonContainer } from "../common-container";
import { Eyebrow } from "../ui";
import * as S from "./LegalDocument.styles";

export type LegalSection = {
  id: string;
  title: string;
  /** Paragraphs; a string array renders as a bullet list. */
  body: (string | string[])[];
};

/**
 * Long-form legal page: summary, sticky table of contents that
 * follows the section being read, and a reading progress bar.
 */
export function LegalDocument({
  eyebrow,
  title,
  updated,
  summary,
  sections,
  related,
}: {
  eyebrow: string;
  title: string;
  updated: string;
  summary: string[];
  sections: LegalSection[];
  related: { to: string; label: string };
}) {
  const [active, setActive] = useState(sections[0].id);
  const article = useRef<HTMLElement>(null);
  const bar = useRef<HTMLSpanElement>(null);

  // Highlight the section nearest the top of the screen.
  useEffect(() => {
    const nodes = sections
      .map((s) => document.getElementById(s.id))
      .filter((n): n is HTMLElement => !!n);
    const io = new IntersectionObserver(
      (entries) => {
        const visible = entries.filter((e) => e.isIntersecting);
        if (visible.length) setActive(visible[0].target.id);
      },
      { rootMargin: "-120px 0px -65% 0px" },
    );
    nodes.forEach((n) => io.observe(n));
    return () => io.disconnect();
  }, [sections]);

  // Reading progress through the document body.
  useEffect(() => {
    let frame = 0;
    const update = () => {
      frame = 0;
      const el = article.current;
      if (!el || !bar.current) return;
      const rect = el.getBoundingClientRect();
      const p = Math.min(
        1,
        Math.max(0, -rect.top / (rect.height - innerHeight)),
      );
      bar.current.style.transform = `scaleX(${p})`;
    };
    const scroll = () => {
      if (!frame) frame = requestAnimationFrame(update);
    };
    update();
    addEventListener("scroll", scroll, { passive: true });
    return () => {
      removeEventListener("scroll", scroll);
      cancelAnimationFrame(frame);
    };
  }, []);

  return (
    <S.Root>
      <S.Progress aria-hidden="true">
        <span ref={bar} />
      </S.Progress>
      <S.Hero>
        <CommonContainer>
          <Eyebrow>{eyebrow}</Eyebrow>
          <h1>{title}</h1>
          <S.Meta>
            <span>Last updated {updated}</span>
          </S.Meta>
        </CommonContainer>
      </S.Hero>
      <CommonContainer>
        <S.Layout>
          <S.Toc aria-label="On this page">
            <strong>On this page</strong>
            <ol>
              {sections.map((s, i) => (
                <li key={s.id}>
                  <a
                    href={`#${s.id}`}
                    aria-current={active === s.id ? "location" : undefined}
                  >
                    <span>{String(i + 1).padStart(2, "0")}</span>
                    {s.title}
                  </a>
                </li>
              ))}
            </ol>
          </S.Toc>
          <S.Article ref={article}>
            <S.Summary>
              <strong>The short version</strong>
              <ul>
                {summary.map((line) => (
                  <li key={line}>{line}</li>
                ))}
              </ul>
            </S.Summary>
            {sections.map((s, i) => (
              <section key={s.id} id={s.id}>
                <h2>
                  <span>{String(i + 1).padStart(2, "0")}</span>
                  {s.title}
                </h2>
                {s.body.map((block, k) =>
                  Array.isArray(block) ? (
                    <ul key={k}>
                      {block.map((item) => (
                        <li key={item}>{item}</li>
                      ))}
                    </ul>
                  ) : (
                    <p key={k}>{block}</p>
                  ),
                )}
              </section>
            ))}
            <S.Related>
              <span>Also read</span>
              <Link to={related.to}>{related.label} →</Link>
              <Link to="/help">Help center →</Link>
            </S.Related>
          </S.Article>
        </S.Layout>
      </CommonContainer>
    </S.Root>
  );
}
