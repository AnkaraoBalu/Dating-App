import styled from "styled-components";
import { Link } from "react-router-dom";
export const Eyebrow = styled.p`
  font-size: 11px;
  letter-spacing: 2.3px;
  text-transform: uppercase;
  font-weight: 800;
  margin-bottom: 24px;
`;
export const Heading = styled.h2`
  font-size: clamp(36px, 5vw, 66px);
  line-height: 1.08;
  font-weight: 600;
  letter-spacing: -2.5px;
  em {
    font-family: "DM Serif", serif;
    font-weight: 400;
    color: #bd3448;
  }
  @media (max-width: 600px) {
    letter-spacing: -1.5px;
  }
`;
export const Copy = styled.p`
  font-size: 16px;
  line-height: 1.9;
  color: #686b67;
  max-width: 590px;
  margin-top: 24px;
`;
export const ButtonLink = styled(Link)<{ $light?: boolean }>`
  display: inline-flex;
  align-items: center;
  justify-content: center;
  gap: 24px;
  padding: 17px 25px;
  border-radius: 100px;
  background: ${({ $light }) => ($light ? "#fff9ef" : "#173f35")};
  color: ${({ $light }) => ($light ? "#173f35" : "#fff9ef")};
  font-size: 13px;
  font-weight: 800;
  transition:
    transform 0.25s,
    box-shadow 0.25s;
  &:hover {
    transform: translateY(-3px);
    box-shadow: 0 8px 24px #173f3520;
  }
  &:active {
    transform: scale(0.98);
  }
`;
export const TextLink = styled(Link)`
  display: inline-flex;
  gap: 18px;
  align-items: center;
  font-size: 13px;
  font-weight: 800;
  border-bottom: 1px solid currentColor;
  padding-bottom: 6px;
`;
export const Section = styled.section<{ $tone?: "forest" | "peach" }>`
  padding: 100px 0;
  background: ${({ $tone }) => ($tone === "forest" ? "#173f35" : $tone === "peach" ? "#f8e5d8" : "transparent")};
  color: ${({ $tone }) => ($tone === "forest" ? "#fff9ef" : "#173f35")};
  @media (max-width: 650px) {
    padding: 70px 0;
  }
`;
export const Split = styled.div`
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 80px;
  align-items: center;
  @media (max-width: 850px) {
    grid-template-columns: 1fr;
    gap: 42px;
  }
`;
export const Actions = styled.div`
  display: flex;
  align-items: center;
  gap: 28px;
  flex-wrap: wrap;
  margin-top: 34px;
`;
export const CardGrid = styled.div`
  display: grid;
  grid-template-columns: repeat(3, 1fr);
  gap: 24px;
  margin-top: 50px;
  @media (max-width: 750px) {
    grid-template-columns: 1fr;
  }
`;
export const Feature = styled.article`
  border-top: 1px solid #173f3530;
  padding-top: 28px;
  span {
    font-size: 30px;
    display: block;
    margin-bottom: 24px;
  }
  h3 {
    font-size: 22px;
    letter-spacing: -0.7px;
  }
  p {
    font-size: 14px;
    color: #686b67;
    margin-top: 14px;
  }
`;
