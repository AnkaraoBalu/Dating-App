import styled from "styled-components";

export const Root = styled.section`
  padding: 80px 0 100px;
  scroll-margin-top: 90px;
  @media (max-width: 650px) {
    padding: 56px 0 70px;
  }
`;
export const Head = styled.div`
  display: flex;
  justify-content: space-between;
  align-items: flex-end;
  gap: 20px;
  flex-wrap: wrap;
`;
export const Count = styled.p`
  font-size: 13px;
  font-weight: 700;
  color: #686b67;
`;
// --pill-x / --pill-w: the active tab, for the sliding highlight.
export const Tabs = styled.div`
  position: relative;
  display: flex;
  width: max-content;
  max-width: 100%;
  margin: 30px 0 18px;
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
    padding: 11px 20px;
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
export const List = styled.div`
  border-top: 1px solid #e5ddd3;
`;
// Height animates by moving the answer's grid row from 0fr to 1fr.
export const Item = styled.div`
  border-bottom: 1px solid #e5ddd3;
  scroll-margin-top: 140px;
  animation: appear 0.45s both;
  animation-delay: calc(var(--i) * 45ms);
  h3 {
    margin: 0;
  }
  button {
    width: 100%;
    display: grid;
    grid-template-columns: 140px 1fr 36px;
    align-items: center;
    gap: 20px;
    padding: 24px 4px;
    border: 0;
    background: none;
    color: #173f35;
    text-align: left;
    transition: color 0.2s;
  }
  button:hover [data-q] {
    color: #bd3448;
  }
  [data-topic] {
    font-size: 11px;
    font-weight: 800;
    letter-spacing: 1.5px;
    text-transform: uppercase;
    color: #8a8d88;
  }
  [data-q] {
    font-size: 19px;
    font-weight: 600;
    letter-spacing: -0.5px;
    transition: color 0.2s;
  }
  [data-icon] {
    position: relative;
    justify-self: end;
    width: 36px;
    height: 36px;
    border-radius: 50%;
    background: #f4ece2;
    transition:
      background 0.3s,
      transform 0.4s cubic-bezier(0.3, 1.4, 0.5, 1);
  }
  [data-icon]::before,
  [data-icon]::after {
    content: "";
    position: absolute;
    left: 11px;
    right: 11px;
    top: 17px;
    height: 2px;
    border-radius: 2px;
    background: currentColor;
  }
  [data-icon]::after {
    transform: rotate(90deg);
    transition: transform 0.3s;
  }
  &[data-open="true"] [data-icon] {
    background: #173f35;
    color: #fff9ef;
    transform: rotate(180deg);
  }
  &[data-open="true"] [data-icon]::after {
    transform: rotate(0deg);
  }
  [data-answer] {
    display: grid;
    grid-template-rows: 0fr;
    transition: grid-template-rows 0.4s cubic-bezier(0.3, 0.9, 0.4, 1);
  }
  [data-answer] > div {
    overflow: hidden;
  }
  &[data-open="true"] [data-answer] {
    grid-template-rows: 1fr;
  }
  p {
    margin: 0 0 26px calc(140px + 24px);
    max-width: 680px;
    color: #4f5550;
    font-size: 15px;
    line-height: 1.75;
    opacity: 0;
    transform: translateY(-6px);
    transition:
      opacity 0.3s,
      transform 0.3s;
  }
  &[data-open="true"] p {
    opacity: 1;
    transform: none;
    transition-delay: 0.1s;
  }
  mark {
    background: #ffc8a8;
    color: inherit;
    border-radius: 4px;
    padding: 0 2px;
  }
  @media (max-width: 700px) {
    button {
      grid-template-columns: 1fr 32px;
      gap: 6px 14px;
      padding: 20px 2px;
    }
    [data-topic] {
      grid-column: 1;
    }
    [data-q] {
      grid-column: 1;
      font-size: 16px;
    }
    [data-icon] {
      grid-column: 2;
      grid-row: 1 / span 2;
    }
    p {
      margin-left: 0;
    }
  }
`;
export const Empty = styled.div`
  padding: 50px 0;
  text-align: center;
  animation: appear 0.4s;
  span {
    font-size: 40px;
  }
  h3 {
    margin-top: 12px;
    font-size: 22px;
  }
  p {
    margin-top: 8px;
    color: #686b67;
  }
  button {
    margin-top: 20px;
    padding: 12px 22px;
    background: #173f35;
    color: #fff9ef;
    border: 0;
    border-radius: 99px;
    font-weight: 700;
  }
`;
