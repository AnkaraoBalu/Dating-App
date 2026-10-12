import { useEffect, useRef } from "react";
import { useReducedMotion } from "../../hooks/useReducedMotion";
import { Pit } from "./Footer.styles";

// Bubbles dropped into the footer: faces plus a few accent shapes. `size` is a fraction of the base size.
const bubbles = [
  { image: "maya", size: 1.1 },
  { glyph: "♥", size: 0.7 },
  { image: "aarav", size: 1 },
  { image: "leah", size: 0.85 },
  { glyph: "✳", size: 0.65 },
  { image: "leo", size: 1.15 },
  { image: "zoe", size: 0.9 },
  { image: "noah", size: 1 },
  { glyph: "♥", size: 0.6 },
  { image: "maya", size: 0.8 },
  { image: "leo", size: 0.75 },
  { image: "aarav", size: 0.9 },
  { glyph: "✳", size: 0.7 },
  { image: "zoe", size: 1.05 },
] as const;

const GRAVITY = 2200; // px/s²
const BOUNCE = 0.35; // restitution against the floor and walls
const STEP = 1 / 120;

type Body = {
  x: number;
  y: number;
  vx: number;
  vy: number;
  r: number;
  angle: number;
  el: HTMLElement;
  dropAt: number; // seconds after start when this bubble is released
  live: boolean;
};

/**
 * Footer pit where faces fall in when it scrolls into view, bounce, roll and
 * pile up. Bubbles can be grabbed and flung. Reduced motion shows the settled pile.
 */
export function FallingFaces() {
  const pit = useRef<HTMLDivElement>(null);
  const reduced = useReducedMotion();

  useEffect(() => {
    const host = pit.current;
    if (!host) return;
    let width = host.clientWidth;
    let height = host.clientHeight;
    const nodes = Array.from(host.children) as HTMLElement[];
    const base = Math.max(58, Math.min(136, width / 10));
    const visibleCount = width < 600 ? 9 : nodes.length;
    const bodies: Body[] = nodes
      .map((el, i) => {
        const r = (base * bubbles[i].size) / 2;
        el.style.width = el.style.height = `${r * 2}px`;
        el.hidden = i >= visibleCount;
        return {
          x: r + ((i * 0.37 + 0.11) % 1) * (width - 2 * r),
          y: -r - 40,
          vx: (((i * 7) % 5) - 2) * 40,
          vy: 0,
          r,
          angle: 0,
          el,
          dropAt: i * 0.12,
          live: false,
        };
      })
      .slice(0, visibleCount);

    let raf = 0;
    let started = false;
    let clock = 0;

    // Lift every bubble back above the pit, ready to drop in again.
    const reset = () => {
      cancelAnimationFrame(raf);
      raf = 0;
      started = false;
      clock = 0;
      bodies.forEach((b, i) => {
        b.x = b.r + ((i * 0.37 + 0.11) % 1) * (width - 2 * b.r);
        b.y = -b.r - 40;
        b.vx = (((i * 7) % 5) - 2) * 40;
        b.vy = 0;
        b.angle = 0;
        b.live = false;
      });
    };
    let last = 0;
    let calm = 0;
    let drag: {
      body: Body;
      dx: number;
      dy: number;
      px: number;
      py: number;
      t: number;
    } | null = null;

    const step = () => {
      clock += STEP;
      for (const b of bodies) {
        if (!b.live) {
          if (clock >= b.dropAt) b.live = true;
          else continue;
        }
        if (drag?.body === b) continue;
        b.vy += GRAVITY * STEP;
        b.x += b.vx * STEP;
        b.y += b.vy * STEP;
        if (b.y + b.r > height) {
          b.y = height - b.r;
          b.vy = Math.abs(b.vy) < 60 ? 0 : -b.vy * BOUNCE;
          b.vx *= 0.985; // rolling friction
        }
        if (b.x - b.r < 0) {
          b.x = b.r;
          b.vx = Math.abs(b.vx) * BOUNCE;
        } else if (b.x + b.r > width) {
          b.x = width - b.r;
          b.vx = -Math.abs(b.vx) * BOUNCE;
        }
        // Roll a little, but keep faces near upright and ease back when resting.
        b.angle = Math.max(
          -0.45,
          Math.min(0.45, b.angle + (b.vx * STEP) / b.r),
        );
        if (Math.abs(b.vx) < 30) b.angle *= 0.97;
      }
      // Circle collisions: separate overlaps, exchange momentum along the normal (mass ∝ r²).
      for (let pass = 0; pass < 3; pass++) {
        for (let i = 0; i < bodies.length; i++) {
          const a = bodies[i];
          if (!a.live) continue;
          for (let j = i + 1; j < bodies.length; j++) {
            const c = bodies[j];
            if (!c.live) continue;
            const dx = c.x - a.x;
            const dy = c.y - a.y;
            const min = a.r + c.r;
            const d2 = dx * dx + dy * dy;
            if (d2 >= min * min || d2 === 0) continue;
            const d = Math.sqrt(d2);
            const nx = dx / d;
            const ny = dy / d;
            const ma = drag?.body === a ? Infinity : a.r * a.r;
            const mc = drag?.body === c ? Infinity : c.r * c.r;
            const ia = ma === Infinity ? 0 : 1 / ma;
            const ic = mc === Infinity ? 0 : 1 / mc;
            if (ia + ic === 0) continue;
            const push = (min - d) / (ia + ic);
            a.x -= nx * push * ia;
            a.y -= ny * push * ia;
            c.x += nx * push * ic;
            c.y += ny * push * ic;
            const rel = (c.vx - a.vx) * nx + (c.vy - a.vy) * ny;
            if (rel < 0) {
              const j2 = (-(1 + 0.2) * rel) / (ia + ic);
              a.vx -= j2 * ia * nx;
              a.vy -= j2 * ia * ny;
              c.vx += j2 * ic * nx;
              c.vy += j2 * ic * ny;
            }
          }
        }
      }
    };

    const render = () => {
      for (const b of bodies) {
        b.el.style.transform = `translate3d(${b.x - b.r}px, ${b.y - b.r}px, 0) rotate(${b.angle}rad)`;
        b.el.style.opacity = b.live ? "1" : "0";
      }
    };

    const frame = (now: number) => {
      raf = 0;
      const dt = last ? Math.min((now - last) / 1000, 0.05) : 1 / 60;
      last = now;
      for (let t = 0; t < dt; t += STEP) step();
      render();
      const moving = bodies.some(
        (b) => !b.live || Math.abs(b.vx) > 4 || Math.abs(b.vy) > 4,
      );
      calm = moving || drag ? 0 : calm + 1;
      if (calm < 30) raf = requestAnimationFrame(frame);
      else last = 0;
    };
    const wake = () => {
      calm = 0;
      if (!raf) raf = requestAnimationFrame(frame);
    };

    const start = () => {
      if (started) return;
      started = true;
      if (reduced) {
        for (let i = 0; i < 900; i++) step();
        render();
      } else wake();
    };
    reset();
    render();
    // Drop when the pit is well in view; reset once it has fully left, so
    // every visit to the footer gets a fresh fall.
    const io = new IntersectionObserver(
      ([entry]) => {
        if (!entry.isIntersecting) {
          reset();
          render();
        } else if (entry.intersectionRatio >= 0.35) start();
      },
      { threshold: [0, 0.35] },
    );
    io.observe(host);

    const resize = new ResizeObserver(() => {
      width = host.clientWidth;
      height = host.clientHeight;
      if (started) wake();
    });
    resize.observe(host);

    // Grab and fling.
    const local = (event: PointerEvent) => {
      const rect = host.getBoundingClientRect();
      return { x: event.clientX - rect.left, y: event.clientY - rect.top };
    };
    const down = (event: PointerEvent) => {
      const target = (event.target as HTMLElement).closest("[data-bubble]");
      const body = bodies.find((b) => b.el === target);
      if (!body || !body.live) return;
      const p = local(event);
      drag = {
        body,
        dx: body.x - p.x,
        dy: body.y - p.y,
        px: p.x,
        py: p.y,
        t: performance.now(),
      };
      body.el.setPointerCapture(event.pointerId);
      body.vx = body.vy = 0;
      wake();
    };
    const move = (event: PointerEvent) => {
      if (!drag) return;
      const p = local(event);
      const now = performance.now();
      const dt = Math.max(0.008, (now - drag.t) / 1000);
      const b = drag.body;
      b.vx = (p.x - drag.px) / dt;
      b.vy = (p.y - drag.py) / dt;
      b.x = Math.max(b.r, Math.min(width - b.r, p.x + drag.dx));
      b.y = Math.min(height - b.r, p.y + drag.dy);
      drag.px = p.x;
      drag.py = p.y;
      drag.t = now;
    };
    const up = () => {
      if (!drag) return;
      const b = drag.body;
      b.vx = Math.max(-2500, Math.min(2500, b.vx));
      b.vy = Math.max(-2500, Math.min(2500, b.vy));
      drag = null;
      wake();
    };
    host.addEventListener("pointerdown", down);
    host.addEventListener("pointermove", move);
    host.addEventListener("pointerup", up);
    host.addEventListener("pointercancel", up);

    return () => {
      cancelAnimationFrame(raf);
      io.disconnect();
      resize.disconnect();
      host.removeEventListener("pointerdown", down);
      host.removeEventListener("pointermove", move);
      host.removeEventListener("pointerup", up);
      host.removeEventListener("pointercancel", up);
    };
  }, [reduced]);

  return (
    <Pit ref={pit} aria-hidden="true">
      {bubbles.map((bubble, i) =>
        "image" in bubble ? (
          <span key={i} data-bubble>
            <img
              src={`/images/${bubble.image}.png`}
              alt=""
              draggable={false}
              loading="lazy"
            />
          </span>
        ) : (
          <span key={i} data-bubble data-glyph>
            {bubble.glyph}
          </span>
        ),
      )}
    </Pit>
  );
}
