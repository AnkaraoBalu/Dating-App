import styled, { css } from "styled-components";

// --spread (0→1): faces move out from the spark onto the orbit.
// --spin (0→1): raw progress; turns the orbit and the spark.
// --text / --cta (0→1): the heading blurs into focus, then the button pops in.
export const Root = styled.section<{ $static: boolean }>`
  --spread: 1;
  --spin: 0.5;
  --text: 1;
  --cta: 1;
  position: relative;
  height: ${({ $static }) => ($static ? "auto" : "170svh")};
  background: linear-gradient(#f8e5d8, #fff9ef 60%);
  &:focus {
    outline: none;
  }
`;
export const Stage = styled.div<{ $static: boolean }>`
  position: ${({ $static }) => ($static ? "relative" : "sticky")};
  top: 0;
  min-height: ${({ $static }) => ($static ? "auto" : "100svh")};
  display: grid;
  place-items: center;
  padding: ${({ $static }) => ($static ? "80px 20px" : "90px 24px 30px")};
  overflow: hidden;
`;

const orbiting = css`
  position: absolute;
  inset: 0;
  --rx: min(560px, 41vw);
  --ry: min(330px, 42svh);
  img {
    --theta: calc(var(--angle) + var(--spin) * 70deg);
    position: absolute;
    top: 50%;
    left: 50%;
    width: var(--size);
    height: var(--size);
    transform: translate(-50%, -50%)
      translate(
        calc(cos(var(--theta)) * var(--rx) * var(--spread)),
        calc(sin(var(--theta)) * var(--ry) * var(--spread) + 30px)
      )
      scale(calc(0.4 + 0.6 * var(--spread)));
    opacity: calc(0.15 + 0.85 * var(--spread));
  }
`;
const row = css`
  display: flex;
  justify-content: center;
  margin-bottom: 30px;
  img {
    width: 64px;
    height: 64px;
    margin-left: -14px;
  }
  img:first-child {
    margin-left: 0;
  }
`;
export const Orbit = styled.div<{ $static: boolean }>`
  pointer-events: none;
  img {
    object-fit: cover;
    border-radius: 50%;
    border: 5px solid #fff9ef;
    box-shadow: 0 16px 36px #173f3526;
  }
  ${({ $static }) => ($static ? row : orbiting)}
`;
export const Copy = styled.div`
  position: relative;
  z-index: 1;
  max-width: 780px;
  text-align: center;
  [data-spark] {
    display: inline-block;
    font-size: 80px;
    line-height: 1;
    color: #bd3448;
    margin-bottom: 18px;
    rotate: calc(var(--spin) * 360deg);
  }
  h2,
  p {
    opacity: var(--text);
    filter: blur(calc((1 - var(--text)) * 12px));
    transform: translateY(calc((1 - var(--text)) * 26px));
  }
  h2 {
    font-size: clamp(42px, 6vw, 78px);
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
    margin: 25px auto 30px;
    max-width: 460px;
    color: #686b67;
    font-size: 15px;
  }
  [data-cta] {
    opacity: var(--cta);
    transform: scale(calc(0.8 + 0.2 * var(--cta)));
  }
  @media (max-width: 600px) {
    h2 {
      letter-spacing: -2px;
    }
  }
`;
