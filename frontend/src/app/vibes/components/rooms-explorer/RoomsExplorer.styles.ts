import styled from "styled-components";

export const Root = styled.section`
  padding: 110px 0 90px;
  @media (max-width: 650px) {
    padding: 70px 0 60px;
  }
`;
export const Intro = styled.div`
  text-align: center;
`;
// --pill-x / --pill-w: position and width of the active tab, for the sliding highlight.
export const Tabs = styled.div`
  position: relative;
  display: flex;
  width: max-content;
  max-width: 100%;
  margin: 36px auto 44px;
  padding: 6px;
  border-radius: 999px;
  background: #f4ece2;
  overflow-x: auto;
  scrollbar-width: none;
  [data-pill] {
    position: absolute;
    top: 6px;
    bottom: 6px;
    left: 0;
    width: var(--pill-w, 0);
    border-radius: 999px;
    background: #173f35;
    transform: translateX(var(--pill-x, 0));
    transition:
      transform 0.45s cubic-bezier(0.3, 1.3, 0.5, 1),
      width 0.45s cubic-bezier(0.3, 1.3, 0.5, 1);
  }
  button {
    position: relative;
    border: 0;
    background: none;
    color: #173f35;
    padding: 12px 22px;
    border-radius: 999px;
    font-size: 14px;
    font-weight: 700;
    white-space: nowrap;
    transition: color 0.3s;
  }
  button[aria-pressed="true"] {
    color: #fff9ef;
  }
`;
export const Grid = styled.div`
  display: grid;
  grid-template-columns: repeat(3, 1fr);
  gap: 26px;
  perspective: 1200px;
  @media (max-width: 950px) {
    grid-template-columns: repeat(2, 1fr);
  }
  @media (max-width: 580px) {
    grid-template-columns: 1fr;
  }
`;
// --i: position, for the staggered deal-in. --tx / --ty (-0.5→0.5): pointer over the card, for the tilt.
export const Card = styled.article`
  --tx: 0;
  --ty: 0;
  border-radius: 24px;
  background: #fffcf7;
  box-shadow: 0 18px 44px #173f3514;
  transform: rotateX(calc(var(--ty) * -10deg)) rotateY(calc(var(--tx) * 12deg));
  transition:
    transform 0.25s ease-out,
    box-shadow 0.3s;
  animation: deal 0.6s cubic-bezier(0.2, 0.9, 0.3, 1.15) both;
  animation-delay: calc(var(--i) * 70ms);
  &:hover {
    box-shadow: 0 28px 60px #173f3526;
  }
  @keyframes deal {
    from {
      opacity: 0;
      translate: 0 40px;
      scale: 0.94;
    }
  }
  > a {
    display: block;
  }
  [data-photo] {
    position: relative;
    height: 260px;
    border-radius: 24px 24px 0 0;
    overflow: hidden;
  }
  [data-photo] > img {
    width: 100%;
    height: 100%;
    object-fit: cover;
    transition: transform 0.7s;
  }
  &:hover [data-photo] > img {
    transform: scale(1.06);
  }
  [data-emoji] {
    position: absolute;
    top: 16px;
    right: 16px;
    display: grid;
    place-items: center;
    width: 58px;
    height: 58px;
    border-radius: 50%;
    background: #fff9ef;
    font-size: 28px;
    box-shadow: 0 8px 20px #0002;
  }
  /* A sample message slides up on hover (always visible on touch screens). */
  [data-preview] {
    position: absolute;
    left: 14px;
    right: 14px;
    bottom: 14px;
    display: flex;
    align-items: flex-end;
    gap: 8px;
    opacity: 0;
    transform: translateY(16px);
    transition:
      opacity 0.3s,
      transform 0.35s cubic-bezier(0.3, 1.4, 0.5, 1);
  }
  [data-preview] img {
    width: 30px;
    height: 30px;
    border-radius: 50%;
    object-fit: cover;
    border: 2px solid #fff9ef;
  }
  [data-preview] p {
    margin: 0;
    padding: 10px 14px;
    border-radius: 16px 16px 16px 4px;
    background: #fff9efee;
    color: #173f35;
    font-size: 12px;
    line-height: 1.4;
    box-shadow: 0 8px 20px #0002;
  }
  &:hover [data-preview],
  &:focus-within [data-preview] {
    opacity: 1;
    transform: none;
  }
  @media (hover: none) {
    [data-preview] {
      opacity: 1;
      transform: none;
    }
  }
  [data-content] {
    padding: 24px 24px 22px;
  }
  [data-group] {
    font-size: 10px;
    font-weight: 800;
    text-transform: uppercase;
    letter-spacing: 2px;
    color: #bd3448;
    margin-bottom: 10px;
  }
  h2 {
    font-size: 24px;
    letter-spacing: -0.8px;
  }
  [data-content] > p {
    font-size: 14px;
    color: #686b67;
    margin-top: 10px;
  }
  [data-foot] {
    display: flex;
    align-items: center;
    justify-content: space-between;
    margin-top: 20px;
  }
  [data-faces] {
    display: flex;
  }
  [data-faces] img {
    width: 30px;
    height: 30px;
    border-radius: 50%;
    object-fit: cover;
    border: 2px solid #fffcf7;
    margin-left: -8px;
  }
  [data-faces] img:first-child {
    margin-left: 0;
  }
  [data-join] {
    font-size: 12px;
    font-weight: 800;
    transition: color 0.2s;
  }
  &:hover [data-join] {
    color: #bd3448;
  }
`;
export const Note = styled.p`
  text-align: center;
  font-size: 12px;
  color: #686b67;
  margin-top: 36px;
`;
