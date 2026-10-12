import styled from "styled-components";

// --in (0→1): cards travel from beyond the corners to their resting spots.
// --text (0→1): the welcome blurs into focus.
export const Root = styled.section<{ $static: boolean }>`
  --in: ${({ $static }) => ($static ? 1 : 0)};
  --text: ${({ $static }) => ($static ? 1 : 0)};
  position: relative;
  height: ${({ $static }) => ($static ? "auto" : "150svh")};
  background:
    radial-gradient(50% 40% at 20% 15%, #ffc8a855, transparent 70%),
    radial-gradient(45% 40% at 85% 85%, #f8e5d8, transparent 70%), #fff9ef;
`;
export const Stage = styled.div<{ $static: boolean }>`
  position: ${({ $static }) => ($static ? "relative" : "sticky")};
  top: 0;
  height: ${({ $static }) => ($static ? "auto" : "100svh")};
  overflow: hidden;
  display: ${({ $static }) => ($static ? "flex" : "grid")};
  flex-direction: column-reverse;
  gap: 50px;
  place-items: center;
  padding: ${({ $static }) => ($static ? "90px 16px" : "0")};
`;
export const Cards = styled.div<{ $static: boolean }>`
  ${({ $static }) =>
    $static
      ? `display: grid; grid-template-columns: 1fr 1fr; gap: 14px; width: min(100%, 480px);`
      : `position: absolute; inset: 0;`}
  > figure {
    ${({ $static }) =>
      $static
        ? `transform: rotate(calc(var(--r) / 3));`
        : `position: absolute; top: 50%; left: 50%;
           transform: translate(-50%, -50%)
             translate(
               calc(var(--x) * (1 + 1.3 * (1 - var(--in)))),
               calc(var(--y) * (1 + 1.3 * (1 - var(--in))))
             )
             rotate(calc(var(--r) * (2 - var(--in))));`}
  }
`;
export const Card = styled.figure`
  margin: 0;
  width: min(270px, 19vw);
  aspect-ratio: 3 / 4;
  border-radius: 26px;
  overflow: hidden;
  box-shadow: 0 30px 60px #173f3526;
  img {
    width: 100%;
    height: 100%;
    object-fit: cover;
  }
  @media (max-width: 850px) {
    width: 100%;
    border-radius: 18px;
  }
`;
export const Copy = styled.div`
  position: relative;
  z-index: 1;
  max-width: 520px;
  text-align: center;
  opacity: var(--text);
  filter: blur(calc((1 - var(--text)) * 14px));
  transform: translateY(calc((1 - var(--text)) * 30px))
    scale(calc(0.94 + 0.06 * var(--text)));
  [data-script] {
    display: block;
    font-family: Caveat;
    font-size: clamp(32px, 3vw, 44px);
    color: #bd3448;
    rotate: -3deg;
  }
  h2 {
    margin-top: 6px;
    font-size: clamp(42px, 5.4vw, 76px);
    line-height: 1.04;
    letter-spacing: -3px;
    font-weight: 600;
  }
  em {
    font-family: "DM Serif", serif;
    font-weight: 400;
    color: #bd3448;
  }
  p {
    margin: 22px auto 30px;
    max-width: 380px;
    color: #686b67;
    font-size: 15px;
  }
  @media (max-width: 650px) {
    h2 {
      letter-spacing: -2px;
    }
  }
`;
