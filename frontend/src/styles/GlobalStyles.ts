import { createGlobalStyle } from "styled-components";
export const GlobalStyles = createGlobalStyle`
  @font-face { font-family: Manrope; src: url('/fonts/Manrope.ttf') format('truetype'); font-weight: 200 800; font-display: swap; }
  @font-face { font-family: 'DM Serif'; src: url('/fonts/DMSerifDisplay-Regular.ttf') format('truetype'); font-display: swap; }
  @font-face { font-family: Caveat; src: url('/fonts/Caveat.ttf') format('truetype'); font-weight: 400 700; font-display: swap; }
  * { box-sizing: border-box; }
  html { scroll-behavior: smooth; scroll-padding-top: 120px; }
  body { margin: 0; font-family: Manrope, system-ui, sans-serif; color: #173f35; background: #fff9ef; -webkit-font-smoothing: antialiased; }
  button, input { font: inherit; }
  button, a { -webkit-tap-highlight-color: transparent; }
  button { cursor: pointer; }
  a { color: inherit; text-decoration: none; }
  img { display: block; max-width: 100%; }
  h1,h2,h3,p { margin: 0; }
  p { line-height: 1.8; }
  ::selection { background: #ffc8a8; color: #173f35; }
  :focus-visible { outline: 3px solid #bd3448; outline-offset: 5px; }
  main:focus { outline: none; }
  @keyframes float { 0%,100% { translate: 0 0; } 50% { translate: 0 -12px; } }
  @keyframes appear { from { opacity: 0; transform: translateY(20px); } to { opacity: 1; transform: translateY(0); } }
  @media (prefers-reduced-motion: reduce) { html { scroll-behavior: auto; } *,*::before,*::after { animation: none !important; transition: none !important; } }
`;
