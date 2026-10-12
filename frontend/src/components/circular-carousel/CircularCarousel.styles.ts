import styled from "styled-components";

// --w / --h: card size. --radius-factor comes from the card count.
// --rot: current ring rotation (set every frame). --spin: optional extra turn from an ancestor.
export const Root = styled.div`
  --w: 320px;
  --h: 420px;
  --radius: calc(var(--w) * var(--radius-factor) + 70px);
  @media (max-width: 650px) {
    --w: 250px;
    --h: 380px;
    --radius: calc(var(--w) * var(--radius-factor) + 30px);
  }
`;
export const Stage = styled.div`
  perspective: 1500px;
  padding: 30px 0;
  cursor: grab;
  touch-action: pan-y;
  user-select: none;
  overflow: hidden;
  outline-offset: -3px;
  &:active {
    cursor: grabbing;
  }
`;
export const Ring = styled.div`
  position: relative;
  width: var(--w);
  height: var(--h);
  margin: auto;
  transform-style: preserve-3d;
  transform: translateZ(calc(-1 * var(--radius)))
    rotateY(calc(var(--rot, 0deg) + var(--spin, 0deg)));
`;
export const Card = styled.article`
  --dist: 0;
  position: absolute;
  inset: 0;
  transform: rotateY(calc(var(--i) * var(--step))) translateZ(var(--radius));
  backface-visibility: hidden;
  opacity: calc(1 - var(--dist) * 0.35);
  border-radius: 28px;
  background: #fffcf7;
  box-shadow: 0 24px 60px #173f3522;
  img {
    pointer-events: none;
  }
`;
export const Controls = styled.div`
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 22px;
  margin-top: 26px;
  > button {
    width: 52px;
    height: 52px;
    border-radius: 50%;
    border: 0;
    background: #173f3512;
    color: #173f35;
    font-size: 20px;
    transition:
      background 0.2s,
      transform 0.2s;
  }
  > button:hover {
    background: #173f3522;
    transform: scale(1.06);
  }
  > button[data-toggle] {
    width: 40px;
    height: 40px;
    font-size: 11px;
    letter-spacing: -1px;
  }
`;
export const Dots = styled.div`
  display: flex;
  gap: 8px;
  button {
    width: 22px;
    height: 6px;
    padding: 0;
    border: 0;
    border-radius: 6px;
    background: #173f3530;
    transition:
      width 0.3s,
      background 0.3s;
  }
  button[aria-current="true"] {
    width: 52px;
    background: #173f35;
  }
`;
export const Live = styled.p`
  position: absolute;
  width: 1px;
  height: 1px;
  overflow: hidden;
  clip-path: inset(50%);
`;
