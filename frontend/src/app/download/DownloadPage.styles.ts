import styled from "styled-components";
export const Layout = styled.div`
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 70px;
  align-items: center;
  padding: 165px 0 100px;
  h1 {
    font-size: clamp(46px, 5.8vw, 78px);
    line-height: 1.08;
    letter-spacing: -3px;
    font-weight: 600;
  }
  h1 em {
    font-family: "DM Serif";
    color: #bd3448;
    font-weight: 400;
  }
  p[data-copy] {
    color: #686b67;
    margin-top: 25px;
    max-width: 460px;
  }
  @media (max-width: 750px) {
    grid-template-columns: 1fr;
    padding-top: 140px;
    gap: 40px;
    h1 {
      letter-spacing: -2px;
    }
  }
`;
export const Stores = styled.div`
  display: flex;
  gap: 12px;
  flex-wrap: wrap;
  margin-top: 32px;
  div {
    padding: 16px 22px;
    border: 1px solid #d2c8bc;
    border-radius: 16px;
    min-width: 180px;
  }
  small {
    display: block;
    font-size: 10px;
    color: #686b67;
    margin-top: 5px;
  }
  strong {
    font-size: 14px;
  }
`;
export const Note = styled.p`
  font-size: 12px !important;
  color: #686b67;
  margin: 20px 0 28px !important;
`;
