import styled from "styled-components";
import { Link } from "react-router-dom";

export const Root = styled.section`
  padding: 90px 0 100px;
  background: #173f35;
  color: #fff9ef;
  @media (max-width: 650px) {
    padding: 64px 0 72px;
  }
`;
export const Head = styled.div`
  text-align: center;
  h2 {
    font-size: clamp(34px, 4.6vw, 60px);
    line-height: 1.08;
    letter-spacing: -2px;
    font-weight: 600;
  }
  em {
    font-family: "DM Serif", serif;
    font-weight: 400;
    color: #ffb0b9;
  }
`;
export const Grid = styled.div`
  display: grid;
  grid-template-columns: repeat(3, 1fr);
  gap: 20px;
  margin-top: 46px;
  > div {
    height: 100%;
  }
  @media (max-width: 850px) {
    grid-template-columns: 1fr;
  }
`;
export const Card = styled(Link)`
  position: relative;
  display: flex;
  flex-direction: column;
  gap: 8px;
  height: 100%;
  padding: 28px;
  border-radius: 24px;
  background: #1d4a3e;
  transition:
    transform 0.3s cubic-bezier(0.3, 1.4, 0.5, 1),
    background 0.3s;
  &:hover {
    transform: translateY(-6px);
    background: #245a4b;
  }
  [data-emoji] {
    font-size: 30px;
    margin-bottom: 8px;
  }
  strong {
    font-size: 20px;
  }
  p {
    color: #c4d6c8;
    font-size: 14px;
  }
  b {
    position: absolute;
    top: 24px;
    right: 26px;
    font-size: 20px;
    color: #ffb0b9;
    transition: transform 0.3s;
  }
  &:hover b {
    transform: translate(4px, -4px);
  }
`;
