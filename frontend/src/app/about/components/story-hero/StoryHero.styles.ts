import styled from "styled-components";

// --open (0→1): the headline parts and the photo grows between the lines.
// --grow (0→1): the scene turns forest, the photo enlarges, side photos arrive.
export const Root = styled.section`
  --open: 0;
  --grow: 0;
  position: relative;
  height: 260svh;
`;
export const Stage = styled.div`
  position: sticky;
  top: 0;
  height: 100svh;
  overflow: hidden;
  background: #fff9ef;
  &::before,
  &::after {
    content: "";
    position: absolute;
    inset: 0;
  }
  &::before {
    background:
      radial-gradient(60% 50% at 15% 30%, #ffc8a8aa, transparent 70%),
      radial-gradient(55% 45% at 90% 75%, #f8e5d8, transparent 70%);
    opacity: calc(1 - var(--grow));
  }
  &::after {
    background: #173f35;
    opacity: var(--grow);
  }
`;
export const Center = styled.div`
  position: absolute;
  z-index: 2;
  top: 50%;
  left: 50%;
  width: calc(
    min(300px, 24vw) + var(--grow) * (min(400px, 30vw) - min(300px, 24vw))
  );
  height: calc(var(--open) * 38svh + var(--grow) * 22svh);
  translate: -50% -50%;
  border-radius: 28px;
  overflow: hidden;
  box-shadow: 0 30px 60px #173f3530;
  img {
    width: 100%;
    height: 100%;
    object-fit: cover;
  }
`;
export const Side = styled.div<{ $side: "left" | "right" }>`
  --dir: ${({ $side }) => ($side === "left" ? -1 : 1)};
  position: absolute;
  z-index: 1;
  top: 50%;
  left: 50%;
  width: min(250px, 19vw);
  aspect-ratio: 3 / 4;
  border-radius: 24px;
  overflow: hidden;
  opacity: var(--grow);
  transform: translate(-50%, -50%)
    translateX(
      calc(
        var(--dir) *
          (
            min(200px, 15vw) + min(125px, 9.5vw) + 40px + (1 - var(--grow)) *
              45vw
          )
      )
    )
    rotate(calc(var(--dir) * 6deg));
  img {
    width: 100%;
    height: 100%;
    object-fit: cover;
  }
`;
export const Copy = styled.div`
  position: absolute;
  z-index: 3;
  top: 50%;
  left: 24px;
  right: 24px;
  translate: 0 -50%;
  text-align: center;
  color: color-mix(in srgb, #fff9ef calc(var(--grow) * 100%), #173f35);
  [data-up] {
    transform: translateY(
      calc(-1 * (var(--open) * (19svh + 12px) + var(--grow) * 3svh))
    );
  }
  [data-down] {
    transform: translateY(
      calc(var(--open) * (19svh + 12px) + var(--grow) * 3svh)
    );
  }
  > div,
  > p {
    position: absolute;
    left: 0;
    right: 0;
    opacity: calc(1 - var(--open) * 1.6);
  }
  > div {
    bottom: 100%;
  }
  h1 {
    font-size: clamp(46px, 7vw, 94px);
    line-height: 1.05;
    letter-spacing: -4px;
    font-weight: 600;
    text-shadow: 0 2px 30px rgb(0 0 0 / calc(var(--grow) * 0.35));
  }
  h1 span {
    display: block;
  }
  em {
    font-family: "DM Serif", serif;
    font-weight: 400;
    color: color-mix(in srgb, #ffb0b9 calc(var(--grow) * 100%), #bd3448);
  }
  > p {
    top: 100%;
    max-width: 620px;
    margin: 28px auto 0;
    color: #686b67;
    font-size: 16px;
  }
`;
export const PhotoRow = styled.div`
  display: grid;
  grid-template-columns: 1fr 1.2fr 1fr;
  gap: 25px;
  align-items: center;
  padding: 10px 0 75px;
  img {
    width: 100%;
    height: 350px;
    object-fit: cover;
    border-radius: 24px;
    transform: rotate(-5deg);
  }
  img:nth-child(2) {
    height: 430px;
    transform: rotate(3deg);
  }
  img:last-child {
    transform: rotate(-3deg);
  }
  @media (max-width: 650px) {
    gap: 10px;
    padding-bottom: 40px;
    img {
      height: 180px;
      border-radius: 12px;
    }
    img:nth-child(2) {
      height: 230px;
    }
  }
`;
