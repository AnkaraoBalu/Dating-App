import styled from "styled-components";
export const Principles = styled.div`
  max-width: 820px;
  margin: 0 auto 100px;
  article {
    display: grid;
    grid-template-columns: 70px 1fr;
    gap: 25px;
    padding: 35px 0;
    border-top: 1px solid #e5ddd3;
  }
  span {
    font-size: 30px;
    color: #bd3448;
  }
  h2 {
    font-size: 24px;
    letter-spacing: -0.8px;
  }
  p {
    font-size: 14px;
    color: #686b67;
    margin-top: 16px;
  }
  @media (max-width: 550px) {
    article {
      grid-template-columns: 30px 1fr;
      gap: 18px;
    }
  }
`;
