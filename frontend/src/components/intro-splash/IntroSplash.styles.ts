import styled, { createGlobalStyle } from "styled-components";

// html[data-intro] is set while the intro runs ("show", then "fly").
export const IntroGlobal = createGlobalStyle`
  html[data-intro] body {
    overflow: hidden;
  }
  html[data-intro] header a[aria-label="Matchify home"] {
    visibility: hidden;
  }
  html[data-intro="show"] main {
    opacity: 0;
    transform: translateY(40px);
  }
  html[data-intro="show"] header > div {
    opacity: 0;
  }
  html[data-intro="fly"] main {
    transition:
      opacity 0.8s ease 0.2s,
      transform 1s cubic-bezier(0.2, 0.9, 0.3, 1) 0.2s;
  }
  html[data-intro="fly"] header > div {
    transition: opacity 0.6s ease 0.25s;
  }
`;
export const Overlay = styled.div`
  position: fixed;
  inset: 0;
  z-index: 100;
  display: grid;
  place-items: center;
  background:
    radial-gradient(60% 50% at 50% 100%, #ffc8a8aa, transparent 70%), #fff9ef;
  pointer-events: none;
  transition: background-color 0.6s;
  &[data-phase="fly"] {
    background: transparent;
    transition: background 0.5s ease;
  }
`;
// Same type styles as the navbar Brand, just larger, so the flight lands seamlessly.
export const Logo = styled.div`
  display: flex;
  align-items: center;
  gap: 0.1em;
  font-size: clamp(64px, 11vw, 150px);
  font-weight: 800;
  letter-spacing: -0.054em;
  line-height: 1.2;
  color: #173f35;
  transform-origin: center;
  animation: logoIn 0.8s cubic-bezier(0.2, 1.2, 0.4, 1) both;
  transition: transform var(--fly) cubic-bezier(0.65, 0, 0.25, 1);
  span {
    font-size: 1.07em;
    color: #bd3448;
    display: inline-block;
    animation: spark 1.2s cubic-bezier(0.3, 1.3, 0.5, 1) 0.2s both;
  }
  @keyframes logoIn {
    from {
      opacity: 0;
      scale: 0.86;
      filter: blur(8px);
    }
  }
  @keyframes spark {
    from {
      rotate: -180deg;
      scale: 0;
    }
  }
`;
