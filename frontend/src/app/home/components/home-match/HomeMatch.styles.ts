import styled from "styled-components";

// --line-1 / --line-2 / --copy (0→1): the heading builds line by line, then the copy.
// --meet / --first are read by MatchDemo: cards slide together, the first stamp lands.
export const Root = styled.section<{ $static: boolean }>`
  --line-1: 1;
  --line-2: 1;
  --copy: 1;
  --meet: 1;
  --first: 1;
  position: relative;
  height: ${({ $static }) => ($static ? "auto" : "170svh")};
  &:focus {
    outline: none;
  }
`;
export const Stage = styled.div<{ $static: boolean }>`
  position: ${({ $static }) => ($static ? "relative" : "sticky")};
  top: 0;
  min-height: ${({ $static }) => ($static ? "auto" : "100svh")};
  display: flex;
  align-items: center;
  padding: ${({ $static }) => ($static ? "80px 0" : "110px 0 40px")};
  overflow: hidden;
`;
export const Layout = styled.div`
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 80px;
  align-items: center;
  @media (max-width: 850px) {
    grid-template-columns: 1fr;
    gap: 42px;
  }
`;
export const Text = styled.div`
  [data-line] {
    display: block;
    opacity: var(--line);
    transform: translateY(calc((1 - var(--line)) * 40px));
  }
  [data-line="1"] {
    --line: var(--line-1);
  }
  [data-line="2"] {
    --line: var(--line-2);
  }
  [data-copy] {
    opacity: var(--copy);
    transform: translateY(calc((1 - var(--copy)) * 24px));
  }
`;
export const Link = styled.div`
  margin-top: 34px;
`;
