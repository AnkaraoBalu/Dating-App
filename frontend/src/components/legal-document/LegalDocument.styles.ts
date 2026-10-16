import styled from "styled-components";

export const Root = styled.div`
  padding-bottom: 100px;
`;
export const Progress = styled.div`
  position: fixed;
  z-index: 60;
  top: 0;
  left: 0;
  right: 0;
  height: 4px;
  span {
    display: block;
    height: 100%;
    background: #bd3448;
    transform: scaleX(0);
    transform-origin: left;
  }
`;
export const Hero = styled.header`
  padding: 170px 0 50px;
  background:
    radial-gradient(45% 60% at 10% 20%, #ffc8a855, transparent 70%), #fff9ef;
  h1 {
    font-size: clamp(42px, 6vw, 84px);
    line-height: 1.04;
    letter-spacing: -3px;
    font-weight: 600;
    animation: appear 0.6s;
  }
  @media (max-width: 650px) {
    padding: 135px 0 36px;
    h1 {
      letter-spacing: -2px;
    }
  }
`;
export const Meta = styled.div`
  display: flex;
  flex-wrap: wrap;
  gap: 10px 18px;
  align-items: center;
  margin-top: 22px;
  font-size: 13px;
  color: #686b67;
`;
export const Layout = styled.div`
  display: grid;
  grid-template-columns: 260px minmax(0, 1fr);
  gap: 70px;
  @media (max-width: 900px) {
    grid-template-columns: 1fr;
    gap: 30px;
  }
`;
export const Toc = styled.nav`
  align-self: start;
  position: sticky;
  top: 130px;
  > strong {
    display: block;
    margin-bottom: 14px;
    font-size: 11px;
    letter-spacing: 1.5px;
    text-transform: uppercase;
    color: #686b67;
  }
  ol {
    margin: 0;
    padding: 0;
    list-style: none;
    border-left: 2px solid #e5ddd3;
  }
  a {
    display: flex;
    gap: 10px;
    margin-left: -2px;
    padding: 8px 14px;
    border-left: 2px solid transparent;
    font-size: 14px;
    color: #686b67;
    transition:
      color 0.2s,
      border-color 0.2s;
  }
  a span {
    font-variant-numeric: tabular-nums;
    color: #b5aea4;
  }
  a:hover,
  a[aria-current] {
    color: #173f35;
  }
  a[aria-current] {
    border-left-color: #bd3448;
    font-weight: 700;
  }
  a[aria-current] span {
    color: #bd3448;
  }
  @media (max-width: 900px) {
    position: static;
    padding: 18px 20px;
    border-radius: 18px;
    background: #fffcf7;
    ol {
      border: 0;
      columns: 2;
    }
    a {
      padding: 6px 0;
      border: 0;
      margin: 0;
    }
  }
  @media (max-width: 520px) {
    ol {
      columns: 1;
    }
  }
`;
export const Article = styled.article`
  max-width: 720px;
  section {
    padding-top: 10px;
    margin-bottom: 44px;
    scroll-margin-top: 120px;
  }
  h2 {
    display: flex;
    align-items: baseline;
    gap: 14px;
    font-size: clamp(24px, 2.4vw, 30px);
    letter-spacing: -0.8px;
    margin-bottom: 14px;
  }
  h2 span {
    font-family: "DM Serif", serif;
    font-weight: 400;
    font-size: 0.8em;
    color: #bd3448;
  }
  p,
  li {
    font-size: 16px;
    line-height: 1.8;
    color: #3f4541;
  }
  p + p,
  p + ul,
  ul + p {
    margin-top: 14px;
  }
  ul {
    margin: 0;
    padding-left: 22px;
  }
  li + li {
    margin-top: 6px;
  }
  li::marker {
    color: #bd3448;
  }
`;
export const Summary = styled.div`
  margin-bottom: 50px;
  padding: 26px 28px;
  border-radius: 24px;
  background: #173f35;
  color: #fff9ef;
  strong {
    display: block;
    margin-bottom: 12px;
    font-size: 18px;
  }
  li {
    color: #dfe9e2;
    font-size: 15px;
  }
  li::marker {
    color: #ffb0b9;
  }
`;
export const Related = styled.div`
  display: flex;
  flex-wrap: wrap;
  gap: 12px 26px;
  align-items: center;
  padding-top: 26px;
  border-top: 1px solid #e5ddd3;
  font-size: 14px;
  span {
    color: #686b67;
  }
  a {
    font-weight: 800;
  }
  a:hover {
    color: #bd3448;
  }
`;
