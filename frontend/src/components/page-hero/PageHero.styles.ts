import styled from "styled-components";
export const Hero = styled.section<{ $center: boolean }>`
  padding: 190px 0 80px;
  text-align: ${({ $center }) => ($center ? "center" : "left")};
  h1 {
    font-size: clamp(46px, 7vw, 94px);
    line-height: 1.05;
    letter-spacing: -4px;
    font-weight: 600;
    max-width: 950px;
    margin: ${({ $center }) => ($center ? "auto" : "0")};
  }
  em {
    font-family: "DM Serif", serif;
    color: #bd3448;
    font-weight: 400;
  }
  p:last-child {
    max-width: 620px;
    margin: 28px ${({ $center }) => ($center ? "auto" : "0")} 0;
    color: #686b67;
    font-size: 16px;
  }
  @media (max-width: 650px) {
    padding: 145px 0 55px;
    h1 {
      letter-spacing: -2px;
    }
  }
`;
