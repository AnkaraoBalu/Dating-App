import { useEffect } from "react";
import { useLocation } from "react-router-dom";
const titles: Record<string, string> = {
  "/": "Find your kind of connection",
  "/about": "Our story",
  "/how-it-works": "How it works",
  "/vibes": "Find your vibe",
  "/help": "Help center",
  "/support": "Support",
  "/download": "Meet the app",
  "/privacy": "Privacy",
  "/terms": "Terms",
  "/community-guidelines": "Our community",
  "/delete-account": "Delete your account",
};
export function RouteEffects() {
  const { pathname, hash } = useLocation();
  useEffect(() => {
    document.title = `${titles[pathname] ?? "Page not found"} · Just2`;
    const pageUrl = new URL(pathname, "https://just2.in").href;
    document.querySelector('link[rel="canonical"]')?.setAttribute("href", pageUrl);
    document.querySelector('meta[property="og:url"]')?.setAttribute("content", pageUrl);
    document.querySelector('meta[property="og:title"]')?.setAttribute("content", document.title);
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
