import styled, { css } from "styled-components";

// --a (0→1): headline settles up, chips fly from around it into a row.
// --b (0→1): a line draws through the row and the copy fades in.
// --gap: spacing between chips in the final row.

export const Title = styled.div`
  position: absolute;
  z-index: 2;
  top: 50%;
  left: 24px;
  right: 24px;
  text-align: center;
  translate: 0 -50%;
  transform: translateY(calc(var(--a) * -17svh))
    scale(calc(1 - 0.32 * var(--a)));
  h1 {
    font-size: clamp(48px, 7.2vw, 104px);
    line-height: 1.04;
    letter-spacing: -4px;
    font-weight: 600;
  }
  em {
    font-family: "DM Serif", serif;
    font-weight: 400;
    color: #bd3448;
  }
`;
export const Path = styled.svg`
  position: absolute;
  z-index: 0;
  top: calc(50% + 15svh);
  left: 50%;
  width: calc(3 * var(--gap));
  height: 70px;
  translate: -50% -50%;
  overflow: visible;
  path {
    fill: none;
    stroke: #bd3448;
    stroke-width: 2.5;
    stroke-linecap: round;
    stroke-dasharray: 1;
    stroke-dashoffset: calc(1 - var(--b));
  }
`;
export const Steps = styled.ol`
  margin: 0;
  padding: 0;
  list-style: none;
`;
export const Step = styled.li`
  position: absolute;
  z-index: 1;
  top: 50%;
  left: 50%;
  display: flex;
  align-items: center;
  gap: 12px;
  padding: 10px 22px 10px 10px;
  border-radius: 999px;
  background: #fffcf7;
  box-shadow: 0 16px 40px #173f3520;
  white-space: nowrap;
  transform: translate(-50%, -50%)
    translate(
      calc(var(--sx) + ((var(--i) - 1.5) * var(--gap) - var(--sx)) * var(--a)),
      calc(var(--sy) + (15svh - var(--sy)) * var(--a))
    )
    rotate(calc(var(--r) * (1 - var(--a))));
  animation: float 5s ease-in-out infinite;
  animation-delay: calc(var(--i) * -1.2s);
  [data-icon] {
    display: grid;
    place-items: center;
    width: 44px;
    height: 44px;
    border-radius: 50%;
    background: #ffc8a8;
    color: #bd3448;
    font-size: 20px;
  }
  [data-text] {
    display: flex;
    flex-direction: column;
    font-size: 15px;
    font-weight: 700;
    line-height: 1.2;
  }
  small {
    font-size: 11px;
    font-weight: 800;
    letter-spacing: 1.5px;
    color: #686b67;
  }
`;
export const Copy = styled.p`
  position: absolute;
  top: calc(50% + 27svh);
  left: 50%;
  width: min(560px, calc(100% - 48px));
  translate: -50% 0;
  text-align: center;
  color: #686b67;
  font-size: 16px;
  opacity: var(--b);
  transform: translateY(calc((1 - var(--b)) * 20px));
`;
export const Hint = styled.span`
  position: absolute;
  bottom: 28px;
  left: 50%;
  translate: -50% 0;
  font-size: 12px;
  font-weight: 800;
  letter-spacing: 1.5px;
  text-transform: uppercase;
  opacity: calc(1 - var(--a) * 2);
`;

const staticLayout = css`
  position: relative;
  height: auto;
  padding: 150px 16px 70px;
  display: grid;
  gap: 34px;
  justify-items: center;
  ${Title}, ${Copy} {
    position: static;
    translate: none;
    transform: none;
    width: auto;
  }
  ${Title} h1 {
    letter-spacing: -2px;
  }
  ${Copy} {
    order: 3;
    max-width: 520px;
  }
  ${Steps} {
    order: 2;
    display: grid;
    gap: 12px;
    width: min(100%, 360px);
  }
  ${Step} {
    position: static;
    transform: none;
    animation: none;
  }
  ${Path}, ${Hint} {
    display: none;
  }
`;

export const Stage = styled.div<{ $static: boolean }>`
  position: sticky;
  top: 0;
  height: 100svh;
  overflow: hidden;
  ${({ $static }) => $static && staticLayout}
`;
export const Root = styled.section<{ $static: boolean }>`
  --a: 0;
  --b: ${({ $static }) => ($static ? 1 : 0)};
  --gap: min(270px, 21vw);
  position: relative;
  height: ${({ $static }) => ($static ? "auto" : "220svh")};
  background:
    radial-gradient(45% 40% at 12% 20%, #ffc8a866, transparent 70%),
    radial-gradient(40% 40% at 92% 80%, #f8e5d8, transparent 70%), #fff9ef;
`;
