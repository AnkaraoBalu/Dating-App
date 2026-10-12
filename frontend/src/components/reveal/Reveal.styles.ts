import styled from "styled-components";
export const Root = styled.div<{ $shown: boolean; $delay: number }>`
  opacity: ${({ $shown }) => ($shown ? 1 : 0)};
  transform: translateY(${({ $shown }) => ($shown ? 0 : 24)}px);
  transition:
    opacity 0.7s ease,
    transform 0.7s cubic-bezier(0.22, 1, 0.36, 1);
  transition-delay: ${({ $delay }) => $delay}s;
`;
