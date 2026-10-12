import styled from "styled-components";

// --enter (0→1) / --spin: the ring fades up and turns into place as the section scrolls in.
export const Root = styled.section`
  --enter: 1;
  --spin: 0deg;
  padding: 110px 0 120px;
  background: linear-gradient(#ffc8a8aa, #f8e5d8 35%, #fff9ef);
  overflow: hidden;
  @media (max-width: 650px) {
    padding: 70px 0 80px;
  }
`;
export const Heading = styled.h2`
  text-align: center;
  font-size: clamp(42px, 5.6vw, 76px);
  line-height: 1.04;
  letter-spacing: -3px;
  font-weight: 600;
  padding: 0 16px;
  em {
    font-family: "DM Serif", serif;
    font-weight: 400;
    color: #bd3448;
  }
  @media (max-width: 650px) {
    letter-spacing: -2px;
  }
`;
export const Ring = styled.div`
  margin-top: 40px;
  opacity: var(--enter);
  transform: translateY(calc((1 - var(--enter)) * 80px));
`;
export const Story = styled.div`
  height: 100%;
  padding: 34px 28px;
  display: flex;
  flex-direction: column;
  align-items: center;
  text-align: center;
  img {
    width: 104px;
    height: 104px;
    border-radius: 50%;
    object-fit: cover;
    box-shadow:
      0 0 0 5px #fff9ef,
      0 10px 24px #173f3526;
  }
  strong {
    margin-top: 18px;
    font-size: 16px;
  }
  small {
    color: #686b67;
    font-size: 13px;
  }
  [data-tag] {
    margin-top: 4px;
    font-family: Caveat;
    font-size: 22px;
    color: #bd3448;
  }
  h3 {
    margin-top: 14px;
    font-size: 25px;
    line-height: 1.15;
    letter-spacing: -0.8px;
    color: #171a18;
  }
  p {
    margin-top: auto;
    padding-top: 14px;
    font-size: 13px;
    line-height: 1.6;
    color: #686b67;
  }
`;
export const Caption = styled.p`
  margin-top: 18px;
  text-align: center;
  font-size: 12px;
  color: #686b67;
`;
