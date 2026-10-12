import styled from "styled-components";
export const Row = styled.div`
  display: flex;
  justify-content: center;
  width: 100%;
  margin-top: 48px;
`;
export const Control = styled.a`
  display: inline-flex;
  align-items: center;
  gap: 14px;
  min-height: 44px;
  padding: 10px 22px;
  border: 1px solid currentColor;
  border-radius: 100px;
  background: transparent;
  color: inherit;
  font-size: 12px;
  font-weight: 600;
  transition:
    background 200ms,
    transform 200ms;
  &:hover {
    background: #bd344815;
    transform: translateY(2px);
  }
  span {
    display: inline-block;
    font-size: 20px;
    animation: scroll-cue 1.8s ease-in-out infinite;
  }
  @keyframes scroll-cue {
    0%,
    100% {
      transform: translateY(-2px);
    }
    50% {
      transform: translateY(3px);
    }
  }
`;
