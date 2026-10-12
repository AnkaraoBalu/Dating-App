import styled from "styled-components";

// --p (0→1): progress through the pinned walkthrough (fills the progress bar).
// --reel: eased step index for the rolling number.
// Per step: --shown (0→1) how visible it is, --side -1 entering from below / 1 leaving upward.
export const Root = styled.section<{ $static: boolean }>`
  --p: 0;
  --reel: 0;
  background: #173f35;
  color: #fff9ef;
  position: relative;
  height: ${({ $static }) => ($static ? "auto" : "300svh")};
  &:focus {
    outline: none;
  }
`;
export const Stage = styled.div<{ $static: boolean }>`
  position: ${({ $static }) => ($static ? "relative" : "sticky")};
  top: 0;
  min-height: ${({ $static }) => ($static ? "auto" : "100svh")};
  display: flex;
  align-items: center;
  padding: 120px 0 50px;
  overflow: hidden;
  @media (max-width: 850px) {
    padding: 80px 0;
  }
`;
export const Content = styled.div`
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 90px;
  align-items: center;
  width: 100%;
`;
export const Reel = styled.span`
  display: inline-block;
  height: 1em;
  line-height: 1;
  overflow: hidden;
  vertical-align: text-bottom;
  color: #ffb0b9;
  > span {
    display: flex;
    flex-direction: column;
    transform: translateY(calc(var(--reel) * -1em));
  }
`;
export const VisuallyHidden = styled.span`
  position: absolute;
  width: 1px;
  height: 1px;
  overflow: hidden;
  clip-path: inset(50%);
`;
export const Texts = styled.div`
  display: grid;
  > div {
    grid-area: 1 / 1;
    opacity: var(--shown, 0);
    filter: blur(calc((1 - var(--shown, 0)) * 6px));
    transform: translateY(calc((1 - var(--shown, 0)) * var(--side, 1) * -48px));
  }
  h2 {
    font-size: clamp(36px, 4.8vw, 65px);
    font-weight: 500;
    letter-spacing: -2px;
    line-height: 1.12;
  }
  h2 em {
    font-family: "DM Serif";
    color: #ffb0b9;
  }
  p {
    margin-top: 25px;
    color: #c4d6c8;
    font-size: 15px;
    max-width: 470px;
  }
`;
export const Portrait = styled.div`
  position: relative;
  display: grid;
  max-width: 370px;
  margin: auto;
  width: 100%;
  figure {
    grid-area: 1 / 1;
    position: relative;
    margin: 0;
  }
  img {
    height: clamp(280px, 50svh, 460px);
    width: 100%;
    object-fit: cover;
    border-radius: 180px 180px 25px 25px;
    clip-path: inset(
      calc((1 - var(--wipe, 0)) * 100%) 0 0 0 round 180px 180px 25px 25px
    );
    transform: scale(calc(1 + (1 - var(--wipe, 0)) * 0.08));
  }
  span {
    position: absolute;
    bottom: 25px;
    left: -20px;
    background: #fff9ef;
    color: #173f35;
    padding: 15px 24px;
    border-radius: 99px;
    font-size: 12px;
    font-weight: 800;
    box-shadow: 0 10px 30px #0002;
    opacity: var(--shown, 0);
    transform: translateX(calc((1 - var(--shown, 0)) * -40px)) rotate(-5deg);
  }
`;
export const Progress = styled.div`
  display: flex;
  gap: 10px;
  margin-top: 36px;
  button {
    position: relative;
    width: 90px;
    height: 30px;
    padding: 0;
    border: 0;
    background: none;
  }
  button::before,
  button::after {
    content: "";
    position: absolute;
    left: 0;
    top: 12px;
    height: 6px;
    border-radius: 6px;
  }
  button::before {
    right: 0;
    background: #fff9ef35;
  }
  button::after {
    width: calc(clamp(0, var(--p) * 3 - var(--i), 1) * 100%);
    background: #ffb0b9;
  }
`;
export const StaticStep = styled.article`
  padding: 40px 0;
  border-bottom: 1px solid #fff9ef30;
  h3 {
    font-size: 29px;
    margin: 14px 0;
  }
  p {
    font-size: 14px;
    color: #c4d6c8;
  }
  span {
    font-size: 12px;
    color: #ffb0b9;
  }
`;
