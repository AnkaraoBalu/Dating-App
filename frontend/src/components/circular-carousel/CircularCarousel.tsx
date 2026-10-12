import { useEffect, useLayoutEffect, useRef, useState } from "react";
import type {
  CSSProperties,
  KeyboardEvent,
  PointerEvent,
  ReactNode,
} from "react";
import { useReducedMotion } from "../../hooks/useReducedMotion";
import * as S from "./CircularCarousel.styles";

type Item = { key: string; label: string; content: ReactNode };

const SPRING = 118; // stiffness of the snap spring (critically damped)
const SETTLE_SPEED = 9; // deg/s below which a coasting ring snaps to a card
const DRAG_THRESHOLD = 6; // px before a press becomes a drag
const HOLD_AFTER_INPUT = 2800; // ms the drift waits after a click/arrow/drag

const mod = (n: number, m: number) => ((n % m) + m) % m;
const clamp = (v: number, min: number, max: number) =>
  Math.min(max, Math.max(min, v));

/**
 * A 3D ring of cards that drifts on its own, eases to a stop on the nearest
 * card while hovered or focused, and resumes when the pointer leaves.
 * Drag (with momentum), horizontal trackpad swipes, clicks, arrows, dots and
 * the arrow / Home / End keys all bring a card forward.
 * Ancestors may set `--spin` (an angle) to add an extra turn, e.g. on scroll.
 */
export function CircularCarousel({
  items,
  label,
  speed = 6,
  momentum = 0.6,
}: {
  items: Item[];
  label: string;
  /** Drift speed in degrees per second; 0 disables autoplay. */
  speed?: number;
  /** 0–1: how long a flick keeps coasting before it snaps. */
  momentum?: number;
}) {
  const count = items.length;
  // Repeat short lists around the ring so neighbours sit at a gentle angle.
  const repeat = Math.max(1, Math.ceil(10 / count));
  const slots = count * repeat;
  const step = 360 / slots;
  const root = useRef<HTMLDivElement>(null);
  const ring = useRef<HTMLDivElement>(null);
  const [activeSlot, setActiveSlot] = useState(0);
  const [paused, setPaused] = useState(false);
  const active = activeSlot % count;
  const reduced = useReducedMotion();
  const autoplay = speed > 0 && !reduced && !paused;

  const state = useRef({
    angle: 0,
    velocity: 0,
    target: null as number | null,
    dir: -1, // drift direction: -1 moves cards to the left
    hover: false,
    focus: false,
    holdUntil: 0,
    press: null as null | {
      id: number;
      x: number;
      angle: number;
      moved: boolean;
      samples: { time: number; angle: number }[];
    },
    drag: false,
    suppressClick: false,
    wheelTimer: 0,
    last: 0,
  });
  const settings = useRef({ autoplay, speed, momentum, reduced, step, slots });
  settings.current = { autoplay, speed, momentum, reduced, step, slots };
  const wake = useRef(() => {});

  useLayoutEffect(() => {
    const s = state.current;
    const el = ring.current;
    const host = root.current;
    if (!el || !host) return;
    let raf = 0;
    let visible = true;
    const nearest = (angle: number) =>
      Math.round(angle / settings.current.step) * settings.current.step;

    const advance = (dt: number, now: number) => {
      const c = settings.current;
      const holding = s.hover || s.focus || s.drag || now < s.holdUntil;
      const cruise = c.autoplay && !holding ? c.speed * s.dir : 0;
      if (s.drag) return true;
      if (s.target !== null) {
        if (c.reduced) {
          s.angle = s.target;
          s.velocity = 0;
          s.target = null;
          return false;
        }
        // Critically damped spring toward the target card.
        const damping = 2 * Math.sqrt(SPRING);
        let remaining = dt;
        while (remaining > 0) {
          const h = Math.min(remaining, 1 / 240);
          const accel = SPRING * (s.target - s.angle) - damping * s.velocity;
          s.velocity += accel * h;
          s.angle += s.velocity * h;
          remaining -= h;
        }
        if (
          Math.abs(s.target - s.angle) < 0.004 &&
          Math.abs(s.velocity) < 0.03
        ) {
          s.angle = s.target;
          s.velocity = 0;
          s.target = null;
        }
        return true;
      }
      // Coast toward the drift speed (or toward rest while held), then snap.
      const tau = 0.18 + c.momentum * 1.5;
      s.velocity += (cruise - s.velocity) * (1 - Math.exp(-dt / tau));
      s.angle += s.velocity * dt;
      if (cruise === 0 && Math.abs(s.velocity) < SETTLE_SPEED) {
        const rest = nearest(s.angle);
        // Already resting on a card while held: stop the loop until something changes.
        if (Math.abs(rest - s.angle) < 0.004) {
          s.angle = rest;
          s.velocity = 0;
          return false;
        }
        s.target = rest;
      }
      return cruise !== 0 || Math.abs(s.velocity) > 0.01 || s.target !== null;
    };

    const render = () => {
      const c = settings.current;
      el.style.setProperty("--rot", `${s.angle}deg`);
      Array.from(el.children).forEach((card, i) => {
        const angle = mod(i * c.step + s.angle + 180, 360) - 180;
        (card as HTMLElement).style.setProperty(
          "--dist",
          String(Math.min(Math.abs(angle) / c.step, 2)),
        );
      });
      setActiveSlot(mod(Math.round(-s.angle / c.step), c.slots));
    };

    const frame = (now: number) => {
      raf = 0;
      const dt = s.last ? Math.min((now - s.last) / 1000, 0.05) : 1 / 60;
      s.last = now;
      const busy = advance(dt, now) || now < s.holdUntil;
      render();
      if (busy && visible && !document.hidden)
        raf = requestAnimationFrame(frame);
      else s.last = 0;
    };
    wake.current = () => {
      if (!raf && visible && !document.hidden)
        raf = requestAnimationFrame(frame);
    };

    // Only animate while on screen and in a visible tab.
    const io = new IntersectionObserver(([entry]) => {
      visible = entry.isIntersecting;
      if (visible) wake.current();
      else {
        cancelAnimationFrame(raf);
        raf = 0;
        s.last = 0;
      }
    });
    io.observe(host);
    const onVisibility = () => {
      if (!document.hidden) return wake.current();
      cancelAnimationFrame(raf);
      raf = 0;
      s.last = 0;
    };
    document.addEventListener("visibilitychange", onVisibility);

    // Horizontal trackpad swipes turn the ring; vertical wheel still scrolls the page.
    const onWheel = (event: WheelEvent) => {
      if (Math.abs(event.deltaX) <= Math.abs(event.deltaY)) return;
      event.preventDefault();
      const perPixel = settings.current.step / cardWidth();
      s.target = null;
      s.angle -= event.deltaX * perPixel;
      s.velocity = -event.deltaX * perPixel * 30;
      s.holdUntil = performance.now() + HOLD_AFTER_INPUT;
      clearTimeout(s.wheelTimer);
      s.wheelTimer = window.setTimeout(() => {
        s.target = nearest(s.angle + s.velocity * 0.12);
        wake.current();
      }, 140);
      wake.current();
    };
    host.addEventListener("wheel", onWheel, { passive: false });

    render();
    wake.current();
    return () => {
      cancelAnimationFrame(raf);
      io.disconnect();
      clearTimeout(s.wheelTimer);
      document.removeEventListener("visibilitychange", onVisibility);
      host.removeEventListener("wheel", onWheel);
    };
  }, []);

  // Settings changed (pause toggled, reduced motion): let the loop react.
  useEffect(() => {
    wake.current();
  }, [autoplay, step]);

  const cardWidth = () =>
    (ring.current?.firstElementChild as HTMLElement | null)?.offsetWidth ?? 300;
  const hold = () => {
    state.current.holdUntil = performance.now() + HOLD_AFTER_INPUT;
  };
  // Nearest rotation that brings `slot` to the front.
  const nearestTo = (slot: number) => {
    const s = state.current;
    const base = -slot * step;
    return base + 360 * Math.round(((s.target ?? s.angle) - base) / 360);
  };
  const goToSlot = (slot: number) => {
    state.current.target = nearestTo(slot);
    hold();
    wake.current();
  };
  // Nearest copy of item `index` on the ring.
  const goTo = (index: number) => {
    const s = state.current;
    const from = s.target ?? s.angle;
    s.target = Array.from({ length: repeat }, (_, k) =>
      nearestTo(index + k * count),
    ).reduce((best, t) =>
      Math.abs(t - from) < Math.abs(best - from) ? t : best,
    );
    hold();
    wake.current();
  };
  const turn = (by: number) => {
    const s = state.current;
    const base = s.target ?? Math.round(s.angle / step) * step;
    s.target = base - by * step;
    s.dir = by > 0 ? -1 : 1;
    hold();
    wake.current();
  };

  const down = (event: PointerEvent<HTMLDivElement>) => {
    const s = state.current;
    s.suppressClick = false;
    if (event.button !== 0) return;
    s.press = {
      id: event.pointerId,
      x: event.clientX,
      angle: s.angle,
      moved: false,
      samples: [{ time: performance.now(), angle: s.angle }],
    };
  };
  const move = (event: PointerEvent<HTMLDivElement>) => {
    const s = state.current;
    const press = s.press;
    if (!press || press.id !== event.pointerId) return;
    const dx = event.clientX - press.x;
    if (!press.moved) {
      if (Math.abs(dx) < DRAG_THRESHOLD) return;
      // Capture only once it is a real drag, so a plain tap still clicks the card.
      press.moved = true;
      s.drag = true;
      s.target = null;
      s.velocity = 0;
      event.currentTarget.setPointerCapture(event.pointerId);
      wake.current();
    }
    s.angle = press.angle + (dx / cardWidth()) * step;
    const now = performance.now();
    press.samples.push({ time: now, angle: s.angle });
    while (press.samples.length > 2 && now - press.samples[0].time > 110)
      press.samples.shift();
  };
  const up = (event: PointerEvent<HTMLDivElement>) => {
    const s = state.current;
    const press = s.press;
    if (!press || press.id !== event.pointerId) return;
    s.press = null;
    if (!press.moved) return;
    s.drag = false;
    s.suppressClick = true;
    // Flick speed from the last ~110ms of the drag, not just the last event.
    const first = press.samples[0];
    const last = press.samples[press.samples.length - 1];
    const span = (last.time - first.time) / 1000;
    const velocity =
      span > 0.008 ? clamp((last.angle - first.angle) / span, -1400, 1400) : 0;
    s.velocity = velocity;
    if (Math.abs(velocity) > 60) s.dir = Math.sign(velocity);
    const tau = 0.18 + momentum * 1.5;
    s.target = Math.round((s.angle + velocity * tau * 0.55) / step) * step;
    hold();
    wake.current();
  };
  const key = (event: KeyboardEvent<HTMLDivElement>) => {
    if (event.key === "ArrowRight") turn(1);
    else if (event.key === "ArrowLeft") turn(-1);
    else if (event.key === "Home") goTo(0);
    else if (event.key === "End") goTo(count - 1);
    else return;
    event.preventDefault();
  };
  const setHover = (hover: boolean) => (event: PointerEvent) => {
    if (event.pointerType !== "mouse") return;
    state.current.hover = hover;
    wake.current();
  };

  return (
    <S.Root
      ref={root}
      role="region"
      aria-roledescription="carousel"
      aria-label={label}
      style={
        {
          "--radius-factor": 1 / (2 * Math.tan(Math.PI / slots)),
        } as CSSProperties
      }
      onFocus={() => {
        state.current.focus = true;
        wake.current();
      }}
      onBlur={(event) => {
        if (event.currentTarget.contains(event.relatedTarget as Node)) return;
        state.current.focus = false;
        wake.current();
      }}
    >
      <S.Stage
        tabIndex={0}
        onPointerDown={down}
        onPointerMove={move}
        onPointerUp={up}
        onPointerCancel={up}
        onKeyDown={key}
        onClickCapture={(event) => {
          if (state.current.suppressClick) {
            state.current.suppressClick = false;
            event.stopPropagation();
          }
        }}
      >
        <S.Ring
          ref={ring}
          onPointerEnter={setHover(true)}
          onPointerLeave={setHover(false)}
        >
          {Array.from({ length: slots }, (_, slot) => {
            const i = slot % count;
            const item = items[i];
            return (
              <S.Card
                key={`${item.key}-${slot}`}
                style={{ "--i": slot, "--step": `${step}deg` } as CSSProperties}
                aria-hidden={slot !== activeSlot}
                aria-roledescription="slide"
                aria-label={`${i + 1} of ${count}: ${item.label}`}
                onClick={() => goToSlot(slot)}
              >
                {item.content}
              </S.Card>
            );
          })}
        </S.Ring>
      </S.Stage>
      <S.Controls>
        <button aria-label="Previous story" onClick={() => turn(-1)}>
          ←
        </button>
        <S.Dots>
          {items.map((item, i) => (
            <button
              key={item.key}
              aria-label={`Show story ${i + 1}: ${item.label}`}
              aria-current={i === active}
              onClick={() => goTo(i)}
            />
          ))}
        </S.Dots>
        <button aria-label="Next story" onClick={() => turn(1)}>
          →
        </button>
        {speed > 0 && !reduced && (
          <button
            data-toggle
            aria-label={paused ? "Play carousel" : "Pause carousel"}
            aria-pressed={paused}
            onClick={() => setPaused(!paused)}
          >
            {paused ? "▶" : "❚❚"}
          </button>
        )}
      </S.Controls>
      {/* Announce only when the visitor is driving it, not on every auto-turn. */}
      <S.Live aria-live={autoplay ? "off" : "polite"}>
        Story {active + 1} of {count}: {items[active].label}
      </S.Live>
    </S.Root>
  );
}
