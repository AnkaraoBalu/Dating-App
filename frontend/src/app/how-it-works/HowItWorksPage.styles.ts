import styled from "styled-components";
export const Detail = styled.article`
  display: grid;
  grid-template-columns: 80px 1fr 1fr;
  gap: 30px;
  padding: 42px 0;
  border-top: 1px solid #e5ddd3;
  span {
    font-family: "DM Serif";
    font-size: 36px;
    color: #bd3448;
  }
  h3 {
    font-size: 25px;
    letter-spacing: -1px;
  }
  p {
    font-size: 14px;
    color: #686b67;
  }
  @media (max-width: 650px) {
    grid-template-columns: 40px 1fr;
    gap: 18px;
    p {
      grid-column: 2;
    }
  }
`;
