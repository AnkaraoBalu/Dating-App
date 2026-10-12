import styled from "styled-components";
export const Container = styled.div`
  width: min(calc(100% - 48px), ${({ theme }) => theme.width});
  margin-inline: auto;
  @media (max-width: 600px) {
    width: calc(100% - 32px);
  }
`;
