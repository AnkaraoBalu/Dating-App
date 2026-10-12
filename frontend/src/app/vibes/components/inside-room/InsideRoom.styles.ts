import styled from "styled-components";

// --p (0→1): progress through the tour. --shift: how far the track has slid left.
// Per panel, --seen (0→1): how centred it is; its mock comes alive as it arrives.
export const Root = styled.section<{ $static: boolean }>`
  --p: 0;
  --shift: 0px;
  --panel: min(1000px, 84vw);
  position: relative;
  height: ${({ $static }) => ($static ? "auto" : "340svh")};
  background: #173f35;
  color: #fff9ef;
`;
export const Stage = styled.div<{ $static: boolean }>`
  position: ${({ $static }) => ($static ? "relative" : "sticky")};
  top: 0;
  min-height: ${({ $static }) => ($static ? "auto" : "100svh")};
  display: flex;
  flex-direction: column;
  justify-content: center;
  gap: 34px;
  padding: ${({ $static }) => ($static ? "80px 0" : "110px 0 40px")};
  overflow: hidden;
`;
export const Head = styled.div`
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 20px;
  width: var(--panel);
  margin: 0 auto;
  p {
    margin: 0;
  }
`;
export const Bar = styled.span`
  position: relative;
  width: 180px;
  height: 4px;
  border-radius: 4px;
  background: #fff9ef30;
  overflow: hidden;
  i {
    position: absolute;
    inset: 0;
    background: #ffb0b9;
    transform-origin: left;
    transform: scaleX(var(--p));
  }
`;
export const Track = styled.div<{ $static: boolean }>`
  display: flex;
  flex-direction: ${({ $static }) => ($static ? "column" : "row")};
  gap: ${({ $static }) => ($static ? "24px" : "40px")};
  width: ${({ $static }) => ($static ? "auto" : "max-content")};
  padding-inline: ${({ $static }) =>
    $static ? "16px" : "calc((100vw - var(--panel)) / 2)"};
  transform: ${({ $static }) => ($static ? "none" : "translateX(var(--shift))")};
`;
export const Panel = styled.article`
  --seen: 1;
  flex: none;
  width: var(--panel);
  max-width: 100%;
  min-height: min(470px, 62svh);
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 50px;
  align-items: center;
  padding: 50px;
  border-radius: 32px;
  background: #1d4a3e;
  opacity: calc(0.45 + 0.55 * var(--seen));
  scale: calc(0.92 + 0.08 * var(--seen));
  [data-num] {
    display: block;
    font-family: "DM Serif", serif;
    font-size: 56px;
    line-height: 1;
    color: #ffb0b9;
  }
  h2 {
    margin-top: 18px;
    font-size: clamp(30px, 3.4vw, 46px);
    line-height: 1.1;
    letter-spacing: -1.5px;
    font-weight: 600;
  }
  [data-text] p {
    margin-top: 18px;
    color: #c4d6c8;
    font-size: 15px;
    max-width: 380px;
  }
  @media (max-width: 850px) {
    grid-template-columns: 1fr;
    gap: 30px;
    padding: 28px;
    min-height: 0;
  }
`;

const card = `
  background: #fffcf7;
  color: #173f35;
  border-radius: 24px;
  padding: 22px;
  box-shadow: 0 24px 50px #0003;
`;
export const Chat = styled.div`
  ${card}
  header {
    display: flex;
    align-items: center;
    gap: 10px;
    padding-bottom: 14px;
    margin-bottom: 16px;
    border-bottom: 1px solid #e5ddd3;
    font-weight: 800;
  }
  header b {
    display: grid;
    place-items: center;
    width: 36px;
    height: 36px;
    border-radius: 50%;
    background: #f8e5d8;
  }
  p {
    display: flex;
    align-items: flex-end;
    gap: 10px;
    margin: 0 0 12px;
    opacity: clamp(0, calc(var(--seen) * 4 - var(--k) - 0.6), 1);
    transform: translateY(
      calc((1 - clamp(0, calc(var(--seen) * 4 - var(--k) - 0.6), 1)) * 14px)
    );
  }
  p:nth-child(odd) {
    flex-direction: row-reverse;
  }
  img {
    width: 32px;
    height: 32px;
    border-radius: 50%;
    object-fit: cover;
  }
  span {
    padding: 11px 14px;
    border-radius: 16px;
    background: #f4ece2;
    font-size: 13px;
    line-height: 1.4;
  }
  p:nth-child(odd) span {
    background: #173f35;
    color: #fff9ef;
  }
`;
export const Games = styled.div`
  [data-chips] {
    display: flex;
    flex-wrap: wrap;
    gap: 8px;
    margin-bottom: 18px;
  }
  [data-chips] span {
    padding: 9px 14px;
    border-radius: 999px;
    border: 1px solid #fff9ef40;
    font-size: 12px;
    font-weight: 700;
    opacity: clamp(0, calc(var(--seen) * 7 - var(--k) - 0.5), 1);
  }
  [data-chips] span:first-child {
    background: #ffb0b9;
    border-color: #ffb0b9;
    color: #173f35;
  }
  [data-poll] {
    ${card}
  }
  [data-poll] strong {
    display: block;
    margin-bottom: 14px;
  }
  [data-option] {
    position: relative;
    padding: 12px 14px;
    margin-top: 8px;
    border-radius: 12px;
    background: #f4ece2;
    font-size: 13px;
    font-weight: 700;
    overflow: hidden;
  }
  [data-option] span {
    position: relative;
    z-index: 1;
  }
  [data-option] i {
    position: absolute;
    inset: 0;
    background: #ffc8a8;
    transform-origin: left;
    transform: scaleX(calc(var(--v) * var(--seen)));
  }
`;
export const Voice = styled.div`
  ${card}
  text-align: center;
  [data-live] {
    display: inline-flex;
    align-items: center;
    gap: 8px;
    padding: 7px 14px;
    border-radius: 999px;
    background: #ffe3e7;
    color: #bd3448;
    font-size: 12px;
    font-weight: 800;
  }
  [data-live] i {
    width: 8px;
    height: 8px;
    border-radius: 50%;
    background: #ff3355;
    animation: livePulse 1.4s ease-in-out infinite;
  }
  [data-speakers] {
    display: flex;
    justify-content: center;
    gap: 14px;
    margin: 26px 0 22px;
  }
  [data-speakers] span {
    position: relative;
    border-radius: 50%;
  }
  [data-speakers] img {
    width: 64px;
    height: 64px;
    border-radius: 50%;
    object-fit: cover;
    border: 3px solid #fffcf7;
    position: relative;
  }
  [data-speaking="true"]::before {
    content: "";
    position: absolute;
    inset: -6px;
    border-radius: 50%;
    border: 3px solid #ff6678;
    animation: speak 1.2s ease-out infinite;
  }
  [data-wave] {
    display: flex;
    justify-content: center;
    align-items: center;
    gap: 4px;
    height: 40px;
  }
  [data-wave] i {
    width: 4px;
    height: 100%;
    border-radius: 4px;
    background: #173f35;
    animation: wave 1s ease-in-out infinite;
    animation-delay: calc(var(--k) * -0.11s);
  }
  @keyframes livePulse {
    50% {
      opacity: 0.3;
    }
  }
  @keyframes speak {
    from {
      transform: scale(0.95);
      opacity: 1;
    }
    to {
      transform: scale(1.3);
      opacity: 0;
    }
  }
  @keyframes wave {
    0%,
    100% {
      transform: scaleY(0.2);
    }
    50% {
      transform: scaleY(1);
    }
  }
`;
export const Create = styled.div`
  ${card}
  strong {
    display: block;
    font-size: 18px;
  }
  [data-emojis] {
    display: flex;
    flex-wrap: wrap;
    gap: 8px;
    margin: 16px 0;
  }
  [data-emojis] span {
    display: grid;
    place-items: center;
    width: 44px;
    height: 44px;
    border-radius: 14px;
    background: #f4ece2;
    font-size: 20px;
  }
  [data-picked="true"] {
    background: #ffb0b9 !important;
    scale: calc(0.9 + 0.2 * var(--seen));
  }
  [data-field] {
    padding: 14px 16px;
    border-radius: 14px;
    border: 2px solid #173f35;
    font-size: 14px;
    font-weight: 700;
  }
  [data-field] span {
    display: inline-block;
    white-space: nowrap;
    clip-path: inset(0 calc((1 - var(--seen)) * 100%) 0 0);
  }
  [data-actions] {
    display: flex;
    justify-content: space-between;
    align-items: center;
    margin-top: 16px;
    font-size: 13px;
    font-weight: 800;
  }
  [data-save] {
    color: #bd3448;
  }
  [data-go] {
    padding: 11px 18px;
    border-radius: 999px;
    background: #173f35;
    color: #fff9ef;
    scale: calc(0.9 + 0.1 * var(--seen));
  }
`;
