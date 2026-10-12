import { useEffect } from "react";
import { useLocation } from "react-router-dom";
const titles: Record<string, string> = {
  "/": "Find your kind of connection",
  "/about": "Our story",
  "/how-it-works": "How it works",
  "/vibes": "Find your vibe",
  "/help": "Help center",
  "/download": "Meet the app",
  "/privacy": "Privacy",
  "/terms": "Terms",
  "/community-guidelines": "Our community",
};
export function RouteEffects() {
  const { pathname, hash } = useLocation();
  useEffect(() => {
    document.title = `${titles[pathname] ?? "Page not found"} · Matchify`;
    const frame = requestAnimationFrame(() => {
      if (hash) {
        document
          .getElementById(decodeURIComponent(hash.slice(1)))
          ?.scrollIntoView();
      } else {
        window.scrollTo({ top: 0, behavior: "instant" });
        document.getElementById("main-content")?.focus({ preventScroll: true });
      }
    });
    return () => cancelAnimationFrame(frame);
  }, [pathname, hash]);
  return null;
}
