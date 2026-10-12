import styled from "styled-components";

// --meet (0→1): the photos drift together and straighten, the heart travels between them.
// --pop (0→1): the heart pops, the note changes and the underline draws.
export const Root = styled.section<{ $static: boolean }>`
  --meet: 0;
  --pop: 0;
  position: relative;
  height: ${({ $static }) => ($static ? "auto" : "200svh")};
  overflow: clip;
  &:focus {
    outline: none;
  }
`;
export const Stage = styled.div<{ $static: boolean }>`
  position: ${({ $static }) => ($static ? "relative" : "sticky")};
  top: 0;
  min-height: 100svh;
  display: flex;
  flex-direction: column;
  justify-content: center;
`;
export const Hero = styled.section`
  padding: 120px 0 20px;
  display: grid;
  grid-template-columns: 1.05fr 1fr;
  gap: 65px;
  align-items: center;
  h1 {
    font-size: clamp(48px, min(6.4vw, 9svh), 88px);
    line-height: 1.04;
    letter-spacing: -4px;
    font-weight: 600;
  }
  h1 em {
    font-family: "DM Serif", serif;
    color: #bd3448;
    font-weight: 400;
    background: linear-gradient(#bd3448, #bd3448) left bottom /
      calc(var(--pop) * 100%) 5px no-repeat;
    padding-bottom: 4px;
  }
  p[data-copy] {
    font-size: 15px;
    max-width: 415px;
    color: #686b67;
    margin-top: 26px;
    line-height: 1.9;
  }
  @media (max-width: 900px) {
    gap: 30px;
  }
  @media (max-width: 750px) {
    grid-template-columns: 1fr;
    padding-top: 145px;
    text-align: center;
    min-height: auto;
    h1 {
      letter-spacing: -2.5px;
    }
    p[data-copy] {
      margin: 24px auto 0;
    }
    [data-actions] {
      justify-content: center;
    }
  }
`;
export const Art = styled.div`
  position: relative;
  height: min(530px, 55svh);
  isolation: isolate;
  &::before {
    content: "";
    position: absolute;
    inset: 40px 15px 15px;
    background: #f5dfcc;
    border-radius: 48% 48% 38% 38%;
    z-index: -1;
    transform: scale(calc(1 + 0.06 * var(--meet)));
  }
  @media (max-width: 900px) {
    height: 470px;
  }
  @media (max-width: 750px) {
    width: min(480px, 100%);
    height: 480px;
    margin: 25px auto 0;
  }
  @media (max-width: 420px) {
    height: 400px;
  }
`;
export const Photo = styled.figure<{ $side: "left" | "right" }>`
  position: absolute;
  top: ${({ $side }) => ($side === "left" ? "20px" : "100px")};
  left: ${({ $side }) => ($side === "left" ? "0" : "auto")};
  right: ${({ $side }) => ($side === "right" ? "0" : "auto")};
  width: 53%;
  height: clamp(240px, 36svh, 350px);
  margin: 0;
  border: 7px solid #fffdf8;
  border-bottom-width: 40px;
  border-radius: 18px;
  box-shadow: 0 16px 40px #173f3520;
  --dir: ${({ $side }) => ($side === "left" ? 1 : -1)};
  transform: translate(
      calc(var(--dir) * var(--meet) * 8%),
      calc(var(--dir) * var(--meet) * 34px)
    )
    rotate(calc(var(--dir) * (-9deg + 5deg * var(--meet))));
  z-index: ${({ $side }) => ($side === "left" ? 1 : 0)};
  /* Entrance: each photo comes forward toward the viewer, then settles back.
     Held while the intro splash runs (html[data-intro]), so it plays as the logo lands. */
  animation: photoPop 1.1s cubic-bezier(0.3, 1.3, 0.5, 1) both;
  animation-delay: ${({ $side }) => ($side === "left" ? "0.05s" : "0.25s")};
  html[data-intro] & {
    animation-play-state: paused;
  }
  @keyframes photoPop {
    0% {
      opacity: 0;
      scale: 0.85;
      translate: 0 40px;
    }
    40% {
      opacity: 1;
      scale: 1.14;
      translate: 0 -14px;
      rotate: ${({ $side }) => ($side === "left" ? "-4deg" : "4deg")};
      box-shadow: 0 40px 80px #173f3540;
    }
    100% {
      scale: 1;
      translate: 0 0;
      rotate: 0deg;
      box-shadow: 0 16px 40px #173f3520;
    }
  }
  img {
    width: 100%;
    height: 100%;
    object-fit: cover;
    border-radius: 10px;
  }
  figcaption {
    font-family: Caveat, cursive;
    position: absolute;
    bottom: -34px;
    left: 12px;
    font-size: 22px;
  }
  @media (max-width: 900px) {
    height: 300px;
  }
  @media (max-width: 420px) {
    height: 260px;
  }
`;
export const Sticker = styled.div`
  position: absolute;
  bottom: 38px;
  left: 12%;
  background: #173f35;
  color: #fff9ef;
  border-radius: 18px;
  padding: 17px 23px;
  box-shadow: 0 12px 30px #173f3520;
  z-index: 3;
  transform: translateY(calc((1 - var(--pop)) * 16px)) rotate(-5deg);
  animation: float 5s ease-in-out infinite;
  font-size: 12px;
  strong {
    font-size: 16px;
    display: block;
    margin-bottom: 4px;
  }
  @media (max-width: 420px) {
    bottom: 10px;
  }
`;
export const Heart = styled.div`
  position: absolute;
  z-index: 2;
  top: calc(55px + var(--meet) * (46% - 55px));
  right: calc(var(--meet) * (50% - 44px));
  background: #ff6678;
  color: #173f35;
  border: 7px solid #fff9ef;
  border-radius: 50%;
  width: 88px;
  height: 88px;
  display: grid;
  place-items: center;
  font-size: 38px;
  transform: rotate(calc(12deg - 12deg * var(--meet)))
    scale(calc(1 + 0.3 * var(--pop) * (1 - var(--pop)) * 4 + 0.15 * var(--pop)));
  animation:
    heartPop 0.6s cubic-bezier(0.3, 1.8, 0.5, 1) 0.75s both,
    float 4s ease-in-out 1.35s infinite;
  html[data-intro] & {
    animation-play-state: paused;
  }
  @keyframes heartPop {
    from {
      opacity: 0;
      scale: 0.2;
    }
  }
`;
export const Handwritten = styled.div`
  font-family: Caveat, cursive;
  position: absolute;
  bottom: 3px;
  right: 0;
  transform: rotate(-6deg);
  font-size: 25px;
  color: #bd3448;
  span {
    display: block;
    white-space: nowrap;
  }
  [data-before] {
    opacity: calc(1 - var(--pop) * 2);
  }
  [data-after] {
    position: absolute;
    right: 0;
    top: 0;
    opacity: calc(var(--pop) * 2 - 1);
  }
  @media (max-width: 420px) {
    display: none;
  }
`;
export const ScrollHint = styled.div`
  > div {
    margin-top: 0;
    width: auto;
  }
  align-items: center;
  @media (max-width: 650px) {
    > span {
      display: none;
    }
    justify-content: center;
  }
  border-top: 1px solid #e5ddd3;
  display: flex;
  justify-content: space-between;
  padding: 25px 0;
  font-size: 10px;
  letter-spacing: 2px;
  text-transform: uppercase;
  gap: 20px;
  color: #686b67;
`;
