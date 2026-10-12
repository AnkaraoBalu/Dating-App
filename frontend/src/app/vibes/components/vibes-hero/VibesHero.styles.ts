import styled, { css } from "styled-components";

// --gather (0→1): bubbles spiral in from far out onto a ring around the headline.
// --more (0→1): the description and link fade in.
// --mx / --my (-1→1): pointer position, for a gentle parallax lean.
export const Root = styled.section<{ $static: boolean }>`
  --gather: 0;
  --more: ${({ $static }) => ($static ? 1 : 0)};
  --mx: 0;
  --my: 0;
  position: relative;
  height: ${({ $static }) => ($static ? "auto" : "200svh")};
  background:
    radial-gradient(40% 45% at 15% 25%, #ffc8a866, transparent 70%),
    radial-gradient(40% 45% at 85% 75%, #ffb0b944, transparent 70%), #fff9ef;
`;
export const Stage = styled.div<{ $static: boolean }>`
  position: ${({ $static }) => ($static ? "relative" : "sticky")};
  top: 0;
  height: ${({ $static }) => ($static ? "auto" : "100svh")};
  display: grid;
  place-items: center;
  padding: ${({ $static }) => ($static ? "150px 16px 60px" : "80px 24px 0")};
  overflow: hidden;
`;

const ring = css`
  position: absolute;
  inset: 0;
  --rx: min(540px, 41vw);
  --ry: min(300px, 34svh);
  span {
    /* Spiral: start further out and a quarter-turn back, end on the ring. */
    --theta: calc(var(--angle) - (1 - var(--gather)) * 70deg);
    --scale: calc(1 + (1 - var(--gather)) * 0.32);
    position: absolute;
    top: calc(50% + 40px);
    left: 50%;
    transform: translate(-50%, -50%)
      translate(
        calc(
          cos(var(--theta)) * var(--rx) * var(--scale) + var(--mx) *
            var(--depth) * 18px
        ),
        calc(
          sin(var(--theta)) * var(--ry) * var(--scale) + var(--my) *
            var(--depth) * 14px
        )
      );
    opacity: calc(0.55 + 0.45 * var(--gather));
  }
`;
const list = css`
  display: flex;
  flex-wrap: wrap;
  justify-content: center;
  gap: 10px;
  order: 2;
  margin-top: 30px;
`;
export const Bubbles = styled.div<{ $static: boolean }>`
  pointer-events: none;
  span {
    display: inline-flex;
    align-items: center;
    gap: 10px;
    padding: 8px 18px 8px 8px;
    border-radius: 999px;
    background: #fffcf7;
    box-shadow: 0 14px 34px #173f351f;
    font-size: 14px;
    font-weight: 700;
    white-space: nowrap;
    animation: float 5s ease-in-out infinite;
    animation-delay: calc(var(--i) * -0.6s);
  }
  b {
    display: grid;
    place-items: center;
    width: 40px;
    height: 40px;
    border-radius: 50%;
    background: #f8e5d8;
    font-size: 20px;
  }
  ${({ $static }) => ($static ? list : ring)}
`;
export const Title = styled.div`
  position: relative;
  z-index: 1;
  max-width: 720px;
  text-align: center;
  h1 {
    font-size: clamp(40px, 5vw, 72px);
    line-height: 1.05;
    letter-spacing: -3px;
    font-weight: 600;
  }
  em {
    font-family: "DM Serif", serif;
    font-weight: 400;
    color: #bd3448;
  }
  p {
    margin: 22px auto 0;
    max-width: 470px;
    color: #686b67;
    font-size: 15px;
  }
  a {
    display: inline-block;
    margin-top: 22px;
    padding-bottom: 5px;
    border-bottom: 1px solid currentColor;
    font-size: 13px;
    font-weight: 800;
  }
  [data-more] {
    opacity: var(--more);
    transform: translateY(calc((1 - var(--more)) * 18px));
  }
  @media (max-width: 600px) {
    h1 {
      letter-spacing: -2px;
    }
  }
`;
