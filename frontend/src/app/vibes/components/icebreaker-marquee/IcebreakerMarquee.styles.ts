import styled from "styled-components";

// --drift (0→1): how far the section has scrolled past; rows slide in opposite directions.
export const Root = styled.section`
  --drift: 0.5;
  padding: 100px 0 110px;
  overflow: hidden;
  background: #fff9ef;
  @media (max-width: 650px) {
    padding: 70px 0 80px;
  }
`;
export const Lead = styled.p`
  text-align: center;
  font-family: Caveat;
  font-size: clamp(26px, 3vw, 36px);
  color: #bd3448;
  margin-bottom: 30px;
  padding: 0 16px;
`;
export const Row = styled.div<{ $reverse: boolean }>`
  padding: 12px 0;
  > div {
    display: flex;
    gap: 44px;
    width: max-content;
    transform: translateX(
      ${({ $reverse }) =>
        $reverse
          ? "calc(-40vw + var(--drift) * 30vw)"
          : "calc(-10vw - var(--drift) * 30vw)"}
    );
  }
  span {
    display: inline-flex;
    align-items: center;
    gap: 18px;
    font-size: clamp(34px, 5.5vw, 76px);
    font-weight: 600;
    letter-spacing: -2px;
    white-space: nowrap;
    color: ${({ $reverse }) => ($reverse ? "#bd3448" : "#173f35")};
  }
  ${({ $reverse }) =>
    $reverse &&
    `span { font-family: "DM Serif", serif; font-weight: 400; letter-spacing: -1px; }`}
  b {
    font-size: 0.6em;
    color: #ffb0b9;
  }
`;
