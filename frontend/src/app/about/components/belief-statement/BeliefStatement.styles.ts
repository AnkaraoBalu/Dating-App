import styled, { css } from "styled-components";

// --shrink (0→1): the lead line settles from headline size into a small intro.
// --reveal (0→1): body words light up one after another.
// --drift (0→1): raw progress, used for the floating shapes' parallax.
export const Root = styled.section<{ $static: boolean }>`
  --shrink: ${({ $static }) => ($static ? 1 : 0)};
  --reveal: ${({ $static }) => ($static ? 1 : 0)};
  --drift: 0.5;
  position: relative;
  height: ${({ $static }) => ($static ? "auto" : "220svh")};
  background: #173f35;
  color: #fff9ef;
`;
export const Stage = styled.div<{ $static: boolean }>`
  position: ${({ $static }) => ($static ? "relative" : "sticky")};
  top: 0;
  height: ${({ $static }) => ($static ? "auto" : "100svh")};
  padding: ${({ $static }) => ($static ? "110px 24px" : "0 24px")};
  display: grid;
  place-items: center;
  overflow: hidden;
`;
export const Text = styled.p`
  position: relative;
  z-index: 1;
  max-width: calc(780px + 300px * var(--shrink));
  text-align: center;
  line-height: 1.08 !important;
  [data-lead] {
    display: block;
    font-size: calc(clamp(36px, 4.6vw, 64px) * (1 - 0.55 * var(--shrink)));
    font-weight: 600;
    letter-spacing: calc(-3px + 2.4px * var(--shrink));
  }
  em {
    display: block;
    margin-top: 6px;
    font-family: "DM Serif", serif;
    font-size: clamp(56px, 8vw, 116px);
    color: #ffb0b9;
    letter-spacing: -2px;
  }
  [data-body] {
    display: block;
    margin-top: 22px;
    font-size: clamp(28px, 3.4vw, 50px);
    font-weight: 600;
    letter-spacing: -1.5px;
    line-height: 1.15;
  }
  [data-body] span {
    opacity: clamp(
      0.12,
      calc(var(--reveal) * (var(--count) + 2) - var(--i)),
      1
    );
  }
  @media (max-width: 650px) {
    em {
      letter-spacing: -1px;
    }
    [data-body] {
      letter-spacing: -0.8px;
    }
  }
`;
const glossy = {
  heart: css`
    top: 14%;
    left: 18%;
    background: radial-gradient(
      circle at 32% 28%,
      #fff 0,
      #ffb0c4 18%,
      #ff5c86 45%,
      #b3184a 85%
    );
    rotate: -14deg;
  `,
  spark: css`
    top: 44%;
    right: 14%;
    background: linear-gradient(
      135deg,
      #fff 10%,
      #c9d1d6 35%,
      #6f7a80 55%,
      #eef2f4 75%,
      #9aa4aa
    );
    rotate: 12deg;
  `,
  smile: css`
    bottom: 9%;
    left: 21%;
    background: radial-gradient(
      circle at 35% 30%,
      #fff7d6 0,
      #ffd36b 30%,
      #ff9f43 65%,
      #d9652b 95%
    );
  `,
};
export const Float = styled.span<{ $at: keyof typeof glossy }>`
  position: absolute;
  font-size: clamp(64px, 8vw, 120px);
  line-height: 1;
  color: transparent;
  filter: drop-shadow(0 18px 22px #0005);
  transform: translateY(calc((0.5 - var(--drift)) * 160px));
  animation: float 6s ease-in-out infinite;
  ${({ $at }) => glossy[$at]}
  -webkit-background-clip: text;
  background-clip: text;
  @media (max-width: 650px) {
    font-size: 48px;
    opacity: 0.8;
  }
`;
