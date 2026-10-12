import styled from "styled-components";

export const Root = styled.section`
  padding: 10px 0 30px;
`;
export const Grid = styled.div`
  display: grid;
  grid-template-columns: repeat(4, 1fr);
  gap: 18px;
  margin-top: -20px;
  > div {
    height: 100%;
  }
  @media (max-width: 950px) {
    grid-template-columns: repeat(2, 1fr);
  }
  @media (max-width: 520px) {
    grid-template-columns: 1fr;
  }
`;
export const Card = styled.button`
  width: 100%;
  height: 100%;
  display: flex;
  flex-direction: column;
  align-items: flex-start;
  gap: 8px;
  padding: 24px;
  border: 0;
  border-radius: 24px;
  background: #fffcf7;
  color: #173f35;
  text-align: left;
  box-shadow: 0 14px 36px #173f3512;
  transition:
    transform 0.3s cubic-bezier(0.3, 1.4, 0.5, 1),
    box-shadow 0.3s;
  &:hover {
    transform: translateY(-6px);
    box-shadow: 0 24px 50px #173f3522;
  }
  [data-emoji] {
    display: grid;
    place-items: center;
    width: 52px;
    height: 52px;
    margin-bottom: 8px;
    border-radius: 16px;
    background: #f8e5d8;
    font-size: 24px;
    transition: transform 0.4s cubic-bezier(0.3, 1.6, 0.5, 1);
  }
  &:hover [data-emoji] {
    transform: rotate(-10deg) scale(1.1);
  }
  strong {
    font-size: 19px;
    letter-spacing: -0.5px;
  }
  p {
    font-size: 13px;
    line-height: 1.55;
    color: #686b67;
  }
  [data-count] {
    margin-top: auto;
    padding-top: 10px;
    font-size: 12px;
    font-weight: 800;
    color: #bd3448;
  }
  [data-count] b {
    display: inline-block;
    transition: transform 0.25s;
  }
  &:hover [data-count] b {
    transform: translateX(5px);
  }
`;
