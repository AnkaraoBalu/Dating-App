import { useState } from "react";
import type { CSSProperties } from "react";
import { Phone } from "./ChatDemo.styles";

const messages = [
  { from: "them", text: "That song you mentioned? Already on repeat. ♫" },
  { from: "me", text: "I knew you’d get it ☺" },
  { from: "them", text: "Same café on Sunday? ☕" },
  { from: "me", text: "Only if you bring the playlist." },
] as const;

/**
 * Chat preview: tap messages to save them, then leave the chat to see viewed
 * messages disappear while saved ones stay. A parent may drive `--msgs` (0→1)
 * to bring the messages in on scroll; without it they are all shown.
 */
export function ChatDemo() {
  const [saved, setSaved] = useState<number[]>([]);
  const [left, setLeft] = useState(false);
  const toggle = (i: number) =>
    setSaved((list) =>
      list.includes(i) ? list.filter((n) => n !== i) : [...list, i],
    );
  const kept = saved.length;

  return (
    <Phone
      data-left={left}
      style={{ "--count": messages.length } as CSSProperties}
    >
      <header>
        <img src="/images/leah.png" alt="" loading="lazy" />
        <div>
          <strong>Leah</strong>
          <p>
            <span data-typing>typing…</span>
            <span data-online>Matched today · interactive preview</span>
          </p>
        </div>
      </header>
      <div data-body>
        {messages.map((message, i) => {
          const isSaved = saved.includes(i);
          return (
            <div
              key={i}
              data-msg
              data-from={message.from}
              data-gone={left && !isSaved}
              style={{ "--i": i } as CSSProperties}
            >
              <div>
                <button
                  aria-pressed={isSaved}
                  aria-label={`${message.text} — ${isSaved ? "saved, tap to unsave" : "tap to save"}`}
                  disabled={left}
                  onClick={() => toggle(i)}
                >
                  {message.text}
                </button>
                {isSaved && <small>▣ Saved in chat</small>}
              </div>
            </div>
          );
        })}
        {left && kept === 0 && (
          <p data-empty>
            The viewed messages disappeared when you left. Return and save one
            before you go.
          </p>
        )}
      </div>
      <footer>
        <button data-leave onClick={() => setLeft(!left)}>
          {left ? "Return to chat ↗" : "Leave chat →"}
        </button>
        <p aria-live="polite">
          {left
            ? kept
              ? "Viewed messages disappeared. Saved ones stay for both of you."
              : "Nothing was saved, so the viewed messages are gone."
            : kept
              ? `${kept} saved. Now leave the chat and see what stays.`
              : "Tap a message to save it, then leave the chat."}
        </p>
        <small>This is an illustration.</small>
      </footer>
    </Phone>
  );
}
