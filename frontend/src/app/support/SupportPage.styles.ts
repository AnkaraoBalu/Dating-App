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
export const Note = styled.p`
  font-size: 12px;
  color: #686b67;
  margin: 20px 0 28px;
  max-width: 460px;
`;
export const Contacts = styled.div`
  display: grid;
  gap: 14px;
`;
export const Contact = styled.a`
  display: flex;
  flex-direction: column;
  gap: 4px;
  padding: 24px 26px;
  border: 1px solid #d2c8bc;
  border-radius: 24px;
  transition:
    transform 0.3s cubic-bezier(0.3, 1.4, 0.5, 1),
    border-color 0.3s;
  &:hover {
    transform: translateY(-4px);
    border-color: #173f35;
  }
  [data-emoji] {
    font-size: 26px;
    margin-bottom: 6px;
  }
  small {
    font-size: 12px;
    color: #686b67;
  }
  strong {
    font-size: clamp(18px, 2vw, 22px);
    overflow-wrap: anywhere;
  }
  p {
    font-size: 13px;
    color: #686b67;
  }
`;
export const Topics = styled.div`
  padding: 24px 26px;
  border-radius: 24px;
  background: #173f35;
  color: #fff9ef;
  strong {
    font-size: 16px;
  }
  ul {
    margin: 12px 0 14px;
    padding-left: 18px;
    display: grid;
    gap: 6px;
    font-size: 14px;
    color: #c4d6c8;
  }
  p {
    font-size: 12px;
    color: #c4d6c8;
  }
`;
export const Deletion = styled.section`
  padding: 56px 0 100px;
  border-top: 1px solid #d2c8bc;
  scroll-margin-top: 120px;
  h2 {
    font-size: clamp(28px, 3.4vw, 40px);
    letter-spacing: -1px;
    font-weight: 600;
  }
  > div {
    display: grid;
    grid-template-columns: repeat(3, 1fr);
    gap: 14px;
    margin-top: 28px;
  }
  section {
    padding: 24px 26px;
    border: 1px solid #d2c8bc;
    border-radius: 24px;
  }
  strong {
    font-size: 16px;
  }
  ol {
    margin-top: 12px;
    padding-left: 18px;
    display: grid;
    gap: 6px;
  }
  p,
  li {
    font-size: 14px;
    color: #686b67;
  }
  p {
    margin-top: 12px;
  }
  a {
    color: #173f35;
    font-weight: 600;
    overflow-wrap: anywhere;
  }
  @media (max-width: 850px) {
    > div {
      grid-template-columns: 1fr;
    }
  }
`;
