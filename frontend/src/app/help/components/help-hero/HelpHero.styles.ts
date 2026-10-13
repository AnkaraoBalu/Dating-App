import styled from "styled-components";

export const Root = styled.section`
  position: relative;
  overflow: hidden;
  padding: 170px 0 80px;
  background:
    radial-gradient(45% 55% at 12% 30%, #ffc8a866, transparent 70%),
    radial-gradient(40% 50% at 88% 70%, #ffb0b944, transparent 70%), #fff9ef;
  @media (max-width: 650px) {
    padding: 135px 0 56px;
  }
`;
export const Marks = styled.div`
  position: absolute;
  inset: 0;
  pointer-events: none;
  span {
    position: absolute;
    font-family: "DM Serif", serif;
    font-size: clamp(40px, 6vw, 90px);
    color: #bd344822;
    animation: float 6s ease-in-out infinite;
    animation-delay: calc(var(--i) * -1.1s);
  }
  span:nth-child(1) {
    left: 8%;
    top: 28%;
    rotate: -12deg;
  }
  span:nth-child(2) {
    left: 18%;
    top: 70%;
  }
  span:nth-child(3) {
    right: 12%;
    top: 24%;
  }
  span:nth-child(4) {
    right: 7%;
    top: 64%;
    rotate: 14deg;
  }
  span:nth-child(5) {
    left: 4%;
    top: 50%;
    font-size: 36px;
    opacity: 0.5;
  }
  span:nth-child(6) {
    right: 24%;
    top: 80%;
    font-size: 42px;
  }
  @media (max-width: 750px) {
    display: none;
  }
`;
export const Content = styled.div`
  position: relative;
  text-align: center;
  animation: appear 0.6s;
  h1 {
    font-size: clamp(46px, 7vw, 96px);
    line-height: 1.02;
    letter-spacing: -4px;
    font-weight: 600;
  }
  em {
    font-family: "DM Serif", serif;
    font-weight: 400;
    color: #bd3448;
  }
  @media (max-width: 600px) {
    h1 {
      letter-spacing: -2px;
    }
  }
`;
export const Search = styled.form`
  position: relative;
  display: flex;
  align-items: center;
  max-width: 680px;
  margin: 38px auto 0;
  padding: 8px 8px 8px 22px;
  border-radius: 999px;
  background: #fffcf7;
  box-shadow:
    0 0 0 1px #e5ddd3,
    0 20px 50px #173f3514;
  transition: box-shadow 0.25s;
  &:focus-within {
    box-shadow:
      0 0 0 2px #bd3448,
      0 24px 60px #173f3522;
  }
  label {
    position: absolute;
    width: 1px;
    height: 1px;
    overflow: hidden;
    clip-path: inset(50%);
  }
  > span {
    font-size: 24px;
    color: #686b67;
    margin-right: 10px;
  }
  input {
    flex: 1;
    min-width: 0;
    border: 0;
    background: none;
    color: #173f35;
    font-size: 17px;
    padding: 14px 0;
    outline: none;
  }
  input::placeholder {
    color: #8a8d88;
  }
  button {
    border: 0;
    border-radius: 999px;
    padding: 15px 26px;
    background: #173f35;
    color: #fff9ef;
    font-size: 14px;
    font-weight: 800;
    transition: transform 0.2s;
  }
  button:hover {
    transform: translateY(-2px);
  }
  @media (max-width: 500px) {
    button {
      padding: 13px 18px;
    }
  }
`;
export const Popular = styled.div`
  display: flex;
  flex-wrap: wrap;
  justify-content: center;
  align-items: center;
  gap: 10px;
  max-width: 760px;
  margin: 24px auto 0;
  > span {
    font-size: 13px;
    font-weight: 700;
    color: #686b67;
  }
  button {
    border: 1px solid #173f3526;
    border-radius: 999px;
    background: #fffcf7aa;
    color: #173f35;
    padding: 9px 16px;
    font-size: 13px;
    font-weight: 600;
    animation: appear 0.5s both;
    animation-delay: calc(0.3s + var(--i) * 0.08s);
    transition:
      background 0.2s,
      border-color 0.2s;
  }
  button:hover {
    background: #fffcf7;
    border-color: #bd3448;
  }
`;
export const Contact = styled.p`
  margin-top: 26px;
  font-size: 14px;
  color: #686b67;
`;
