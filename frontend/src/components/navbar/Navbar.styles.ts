import styled from "styled-components";
import { Link, NavLink } from "react-router-dom";
export const Header = styled.header`
  position: fixed;
  top: 24px;
  left: 0;
  right: 0;
  z-index: 50;
  padding: 0 24px;
  @media (max-width: 850px) {
    top: 14px;
    padding: 0 16px;
  }
`;
export const Capsule = styled.div`
  max-width: 1250px;
  margin: auto;
  display: flex;
  justify-content: space-between;
  align-items: center;
  gap: 24px;
  border: 1px solid #173f3520;
  background: #fff9efed;
  backdrop-filter: blur(20px);
  box-shadow: 0 4px 24px #173f3508;
  border-radius: 100px;
  padding: 13px 16px 13px 30px;
`;
export const Brand = styled(Link)`
  display: flex;
  align-items: center;
  width: 112px;
  flex-shrink: 0;
  @media (max-width: 480px) {
    width: 86px;
  }
`;
export const Desktop = styled.nav`
  display: flex;
  align-items: center;
  gap: 34px;
  @media (max-width: 1100px) {
    gap: 22px;
  }
  @media (max-width: 1000px) {
    gap: 16px;
  }
  @media (max-width: 850px) {
    display: none;
  }
`;
export const NavItem = styled(NavLink)`
  font-size: 15px;
  font-weight: 700;
  transition: color 0.2s;
  &.active {
    color: #bd3448;
  }
  &:hover {
    color: #bd3448;
  }
`;
export const Cta = styled(Link)`
  background: #173f35;
  color: #fff9ef;
  font-size: 14px;
  font-weight: 800;
  padding: 15px 22px;
  border-radius: 99px;
  transition: transform 0.2s;
  &:hover {
    transform: translateY(-2px);
  }
  @media (max-width: 850px) {
    margin-left: auto;
  }
  @media (max-width: 480px) {
    font-size: 10px;
    padding: 12px 14px;
  }
`;
export const MenuButton = styled.button`
  display: none;
  border: 0;
  background: transparent;
  font-size: 23px;
  padding: 7px;
  color: inherit;
  @media (max-width: 850px) {
    display: block;
  }
`;
export const Dialog = styled.dialog`
  border: 0;
  margin: 0;
  padding: 0;
  width: 100%;
  max-width: none;
  height: 100dvh;
  max-height: none;
  background: #173f35;
  color: #fff9ef;
  z-index: 100;
  &::backdrop {
    background: #173f35;
  }
  [data-top] {
    display: flex;
    justify-content: space-between;
    align-items: center;
    padding: 30px 26px;
  }
  button {
    border: 1px solid #fff9ef55;
    border-radius: 50%;
    color: inherit;
    background: transparent;
    width: 44px;
    height: 44px;
    font-size: 24px;
  }
  nav {
    display: flex;
    flex-direction: column;
    gap: 25px;
    padding: 35px 28px;
  }
  nav a {
    font-size: clamp(27px, 5vh, 42px);
    font-weight: 600;
    letter-spacing: -1px;
    animation: appear 0.5s both;
  }
  nav a.active {
    color: #ff9eaa;
  }
  p {
    padding: 24px 28px;
    color: #c4d6c8;
    font-size: 13px;
  }
  @media (min-width: 851px) {
    display: none;
  }
`;
export const Skip = styled.a`
  position: fixed;
  top: -100px;
  left: 20px;
  background: #fff9ef;
  padding: 12px;
  z-index: 110;
  &:focus {
    top: 10px;
  }
`;
