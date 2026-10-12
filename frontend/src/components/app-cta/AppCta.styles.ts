import styled from "styled-components";
export const Root = styled.section`
  text-align: center;
  padding: 100px 24px 110px;
  background: #f8e5d8;
  position: relative;
  overflow: hidden;
  h2 {
    font-size: clamp(42px, 6vw, 78px);
    line-height: 1.05;
    letter-spacing: -3px;
    font-weight: 600;
    max-width: 770px;
    margin: auto;
  }
  em {
    font-family: "DM Serif", serif;
    color: #bd3448;
  }
  p {
    margin: 25px auto 30px;
    max-width: 460px;
    color: #686b67;
    font-size: 14px;
  }
  [data-spark] {
    font-size: 80px;
    color: #bd3448;
    display: block;
    margin-bottom: 20px;
    line-height: 1;
    animation: float 5s ease-in-out infinite;
  }
  @media (max-width: 600px) {
    padding: 70px 20px;
    h2 {
      letter-spacing: -2px;
    }
  }
`;
