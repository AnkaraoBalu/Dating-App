import styled from "styled-components";

// Optional scroll inputs from a parent (default 1 = settled):
// --meet: cards slide in from the sides; --first: the first "liked you" stamp lands.
export const Demo = styled.div`
  width: 100%;
  max-width: 430px;
  margin: auto;
  text-align: center;
`;
export const Pair = styled.div`
  height: 345px;
  position: relative;
  margin: 25px 0;
  animation: appear 0.5s;
  figure {
    position: absolute;
    margin: 0;
    width: 55%;
    height: 300px;
  }
  img {
    width: 100%;
    height: 100%;
    object-fit: cover;
    border: 6px solid #fff9ef;
    border-radius: 24px;
    box-shadow: 0 10px 25px #0002;
  }
  [data-side="left"] {
    left: 0;
    top: 0;
    transform: translateX(calc((1 - var(--meet, 1)) * -70%))
      rotate(calc(-9deg - (1 - var(--meet, 1)) * 12deg));
    opacity: calc(0.2 + 0.8 * var(--meet, 1));
  }
  [data-side="right"] {
    right: 0;
    top: 30px;
    transform: translateX(calc((1 - var(--meet, 1)) * 70%))
      rotate(calc(9deg + (1 - var(--meet, 1)) * 12deg));
    opacity: calc(0.2 + 0.8 * var(--meet, 1));
  }
  [data-stamp] {
    position: absolute;
    top: 18px;
    padding: 8px 14px;
    border: 2px solid #ff6678;
    border-radius: 10px;
    background: #fff9efee;
    color: #bd3448;
    font-size: 13px;
    font-weight: 800;
    letter-spacing: 0.5px;
    text-transform: uppercase;
  }
  [data-side="left"] [data-stamp] {
    left: 16px;
    opacity: var(--first, 1);
    transform: rotate(-8deg) scale(calc(1.6 - 0.6 * var(--first, 1)));
  }
  [data-side="right"] [data-stamp] {
    right: 16px;
    opacity: 0;
    transform: rotate(8deg) scale(1.6);
    transition:
      opacity 0.25s,
      transform 0.35s cubic-bezier(0.3, 1.6, 0.5, 1);
  }
  &[data-matched="true"] [data-side="right"] [data-stamp] {
    opacity: 1;
    transform: rotate(8deg) scale(1);
  }
  @media (max-width: 420px) {
    height: 280px;
    figure {
      height: 245px;
    }
  }
`;
export const Heart = styled.span`
  position: absolute;
  z-index: 2;
  left: calc(50% - 35px);
  top: 130px;
  width: 70px;
  height: 70px;
  border-radius: 50%;
  background: #ff6678;
  color: #173f35;
  display: grid;
  place-items: center;
  font-size: 32px;
  border: 5px solid #fff9ef;
  transform: scale(0);
  transition: transform 0.45s cubic-bezier(0.3, 1.8, 0.5, 1) 0.15s;
  [data-matched="true"] > & {
    transform: scale(1);
  }
  i {
    position: absolute;
    font-style: normal;
    font-size: 16px;
    color: #ff6678;
    opacity: 0;
  }
  [data-matched="true"] > & i {
    animation: burst 0.8s ease-out 0.25s;
  }
  @keyframes burst {
    0% {
      opacity: 1;
      transform: rotate(var(--a)) translateY(0) scale(0.6);
    }
    100% {
      opacity: 0;
      transform: rotate(var(--a)) translateY(-80px) scale(1.1);
    }
  }
`;
export const Controls = styled.div`
  display: flex;
  justify-content: center;
  gap: 14px;
  button {
    min-height: 48px;
    border-radius: 99px;
    padding: 12px 26px;
    background: transparent;
    color: inherit;
    border: 1px solid currentColor;
    font-weight: 700;
    font-size: 13px;
    transition: transform 0.2s;
  }
  button[data-primary] {
    background: #ff6678;
    color: #173f35;
    border-color: #ff6678;
    animation: nudge 2.4s ease-in-out infinite;
  }
  button:hover {
    transform: translateY(-3px);
  }
  @keyframes nudge {
    0%,
    100% {
      box-shadow: 0 0 0 0 #ff667866;
    }
    50% {
      box-shadow: 0 0 0 12px #ff667800;
    }
  }
`;
export const Status = styled.p`
  min-height: 48px;
  font-size: 14px;
  margin: 20px 0 0 !important;
  color: inherit !important;
`;
export const Caption = styled.p`
  font-size: 10px !important;
  opacity: 0.7;
  margin: 12px 0 0 !important;
`;
