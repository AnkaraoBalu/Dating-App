import styled from "styled-components";

// --chips (0→1): interests fade in one after another.
// --reveal (0→1): heading words light up in order.
// --para / --note (0→1): the paragraph, then the handwritten note.
// --drift (0→1): raw progress, for parallax and the ticker.
export const Root = styled.section<{ $static: boolean }>`
  --chips: ${({ $static }) => ($static ? 1 : 0)};
  --reveal: ${({ $static }) => ($static ? 1 : 0)};
  --para: ${({ $static }) => ($static ? 1 : 0)};
  --note: ${({ $static }) => ($static ? 1 : 0)};
  --drift: 0.5;
  position: relative;
  height: ${({ $static }) => ($static ? "auto" : "200svh")};
  &:focus {
    outline: none;
  }
`;
export const Stage = styled.div<{ $static: boolean }>`
  position: ${({ $static }) => ($static ? "relative" : "sticky")};
  top: 0;
  min-height: ${({ $static }) => ($static ? "auto" : "100svh")};
  display: flex;
  flex-direction: column;
  justify-content: center;
  padding: ${({ $static }) => ($static ? "70px 0 0" : "110px 0 0")};
  overflow: hidden;
  text-align: center;
`;
export const Chips = styled.div`
  position: absolute;
  inset: 0;
  pointer-events: none;
  span {
    position: absolute;
    left: var(--x);
    top: var(--y);
    padding: 12px 20px;
    border-radius: 999px;
    background: #fffcf7;
    box-shadow: 0 14px 34px #173f351c;
    font-size: 14px;
    font-weight: 700;
    white-space: nowrap;
    opacity: clamp(0, calc(var(--chips) * 7 - var(--i)), 1);
    transform: translateY(calc((0.5 - var(--drift)) * var(--depth) * 220px))
      rotate(var(--r));
  }
  b {
    color: #bd3448;
    margin-right: 6px;
  }
  @media (max-width: 850px) {
    display: none;
  }
`;
export const Copy = styled.div`
  position: relative;
  z-index: 1;
  h2 {
    max-width: 900px;
    margin: auto;
    font-size: clamp(36px, 5vw, 66px);
    line-height: 1.08;
    font-weight: 600;
    letter-spacing: -2.5px;
  }
  h2 span {
    opacity: clamp(
      0.14,
      calc(var(--reveal) * (var(--count) + 2) - var(--i)),
      1
    );
  }
  em {
    font-family: "DM Serif", serif;
    font-weight: 400;
    color: #bd3448;
  }
  [data-para] {
    max-width: 550px;
    margin: 25px auto 0;
    color: #686b67;
    opacity: var(--para);
    transform: translateY(calc((1 - var(--para)) * 16px));
  }
  [data-note] {
    width: max-content;
    max-width: 100%;
    margin: 22px auto 0;
    font-family: Caveat;
    font-size: 30px;
    line-height: 1.3;
    color: #bd3448;
    clip-path: inset(-10% calc((1 - var(--note)) * 100%) -10% 0);
  }
  @media (max-width: 600px) {
    h2 {
      letter-spacing: -1.5px;
    }
  }
`;
export const Ticker = styled.div`
  margin-top: 46px;
  overflow: hidden;
  background: #f8e5d8;
  padding: 22px 0;
  border-block: 1px solid #e5ddd3;
  > div {
    width: max-content;
    display: flex;
    gap: 50px;
    animation: travel 40s linear infinite;
    translate: calc(var(--drift) * -18vw) 0;
  }
  > div > span {
    display: flex;
    gap: 50px;
  }
  span span {
    font-size: 15px;
    letter-spacing: 1px;
    white-space: nowrap;
    font-weight: 700;
  }
  b {
    color: #bd3448;
    margin-right: 14px;
  }
  @keyframes travel {
    to {
      transform: translateX(-50%);
    }
  }
`;
