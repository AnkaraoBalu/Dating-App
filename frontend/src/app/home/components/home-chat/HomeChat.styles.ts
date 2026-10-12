import styled from "styled-components";

// --phone (0→1): the phone rises in. --msgs is read by ChatDemo (messages arrive).
// --line-1 / --line-2 / --copy (0→1): the heading builds line by line, then the copy.
export const Root = styled.section<{ $static: boolean }>`
  --phone: 1;
  --msgs: 1;
  --line-1: 1;
  --line-2: 1;
  --copy: 1;
  position: relative;
  height: ${({ $static }) => ($static ? "auto" : "170svh")};
  background: #f8e5d8;
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
export const PhoneSlot = styled.div`
  opacity: calc(0.2 + 0.8 * var(--phone));
  transform: translateY(calc((1 - var(--phone)) * 120px))
    rotate(calc((1 - var(--phone)) * -6deg));
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
export const Steps = styled.ol`
  display: flex;
  flex-wrap: wrap;
  gap: 10px;
  margin: 26px 0 32px;
  padding: 0;
  list-style: none;
  li {
    display: flex;
    align-items: center;
    gap: 8px;
    padding: 8px 14px 8px 8px;
    border-radius: 999px;
    background: #fffcf7;
    font-size: 12px;
    font-weight: 700;
  }
  b {
    display: grid;
    place-items: center;
    width: 22px;
    height: 22px;
    border-radius: 50%;
    background: #ff6678;
    color: #173f35;
    font-size: 11px;
  }
`;
