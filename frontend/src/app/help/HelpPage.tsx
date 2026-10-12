import { useEffect, useState } from "react";
import { useLocation } from "react-router-dom";
import { questions } from "./data/questions";
import { HelpHero } from "./components/help-hero";
import { HelpTopics } from "./components/help-topics";
import { FaqList } from "./components/faq-list";
import { HelpMore } from "./components/help-more";

export type Category = "All questions" | (typeof questions)[number]["category"];

export function HelpPage() {
  const [query, setQuery] = useState("");
  const [category, setCategory] = useState<Category>("All questions");
  const [open, setOpen] = useState<string | null>(null);
  const { hash } = useLocation();

  // Deep links like /help#chat clear filters, open that answer and scroll to it.
  useEffect(() => {
    const id = hash.slice(1);
    if (!questions.some((q) => q.id === id)) return;
    setCategory("All questions");
    setQuery("");
    setOpen(id);
    requestAnimationFrame(() =>
      document.getElementById(id)?.scrollIntoView({ block: "center" }),
    );
  }, [hash]);

  const term = query.toLowerCase().trim();
  const shown = questions.filter(
    (q) =>
      (category === "All questions" || q.category === category) &&
      `${q.question} ${q.answer}`.toLowerCase().includes(term),
  );
  const showAnswers = (next?: Category) => {
    if (next) setCategory(next);
    document.getElementById("answers")?.scrollIntoView({ behavior: "smooth" });
  };
  const openQuestion = (id: string) => {
    setCategory("All questions");
    setQuery("");
    setOpen(id);
    requestAnimationFrame(() =>
      document
        .getElementById(id)
        ?.scrollIntoView({ behavior: "smooth", block: "center" }),
    );
  };

  return (
    <>
      <HelpHero
        query={query}
        onQuery={(value) => {
          setQuery(value);
          setCategory("All questions");
        }}
        onSubmit={() => showAnswers()}
        onPopular={openQuestion}
      />
      <HelpTopics onPick={(topic) => showAnswers(topic)} />
      <FaqList
        shown={shown}
        term={term}
        category={category}
        onCategory={setCategory}
        open={open}
        onToggle={(id) => setOpen(open === id ? null : id)}
        onClear={() => {
          setQuery("");
          setCategory("All questions");
        }}
      />
      <HelpMore />
    </>
  );
}
