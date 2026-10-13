import styled from "styled-components";

export const Root = styled.footer`
  background: #102d26;
  color: #fff9ef;
`;
export const Panel = styled.div`
  position: relative;
  z-index: 2;
  background: #fff9ef;
  color: #173f35;
  border-top: 1px solid #e5ddd3;
  border-radius: 0 0 44px 44px;
  padding: 52px 0 46px;
  box-shadow: 0 20px 40px #0000002e;
  @media (max-width: 600px) {
    border-radius: 0 0 28px 28px;
    padding: 40px 0 34px;
  }
`;
export const Top = styled.div`
  display: flex;
  justify-content: space-between;
  align-items: flex-start;
  gap: 40px;
  flex-wrap: wrap;
  nav {
    display: flex;
    gap: 80px;
  }
  nav div {
    display: flex;
    flex-direction: column;
    gap: 12px;
    font-size: 14px;
  }
  nav strong {
    color: #686b67;
    font-size: 11px;
    letter-spacing: 1.5px;
    text-transform: uppercase;
    margin-bottom: 4px;
  }
  nav a {
    width: max-content;
    font-weight: 600;
    transition: color 0.2s;
  }
  a:hover {
    color: #bd3448;
  }
  @media (max-width: 600px) {
    nav {
      gap: 50px;
    }
  }
`;
export const Brand = styled.div`
  > a {
    display: block;
    width: 140px;
  }
  p {
    margin-top: 12px;
    max-width: 320px;
    color: #686b67;
    font-size: 14px;
    line-height: 1.6;
  }
`;
export const Band = styled.div`
  position: relative;
  /* Tucks under the panel so its rounded corners sit on the forest band. */
  margin-top: -44px;
  height: clamp(300px, 30vw, 400px);
  overflow: hidden;
  background: radial-gradient(70% 90% at 50% 0%, #1d4a3e, #102d26 70%);
  @media (max-width: 600px) {
    margin-top: -28px;
    height: 260px;
  }
`;
export const Wordmark = styled.div`
  width: min(60vw, 600px);
  opacity: 0.25;
  position: absolute;
  left: 50%;
  top: 46%;
  translate: -50% -50%;
  user-select: none;
`;
export const Pit = styled.div`
  position: absolute;
  inset: 44px 0 0;
  [data-bubble] {
    position: absolute;
    left: 0;
    top: 0;
    display: grid;
    place-items: center;
    border-radius: 50%;
    overflow: hidden;
    border: 4px solid #fff9ef;
    box-shadow: 0 12px 28px #0006;
    background: #fff9ef;
    cursor: grab;
    touch-action: none;
    user-select: none;
    opacity: 0;
    will-change: transform;
  }
  [data-bubble]:active {
    cursor: grabbing;
  }
  img {
    width: 100%;
    height: 100%;
    object-fit: cover;
    pointer-events: none;
  }
  [data-glyph] {
    background: radial-gradient(
      circle at 32% 28%,
      #ffd0d8,
      #ff6678 55%,
      #bd3448
    );
    color: #fff9ef;
    font-size: 1.6em;
  }
`;
export const Bottom = styled.div`
  display: flex;
  justify-content: center;
  gap: 8px 28px;
  flex-wrap: wrap;
  padding: 16px;
  border-top: 1px solid #fff9ef14;
  color: #b5c8bc;
  font-size: 12px;
`;
