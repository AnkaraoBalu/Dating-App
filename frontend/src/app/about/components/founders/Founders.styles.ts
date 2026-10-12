import styled from "styled-components";

// --card-0 / --card-1 (0→1): each card rises, untilts and fades in, the second a beat later.
// Inside a card, --in points at its own value and --dir is -1 (left) or 1 (right).
export const Root = styled.section<{ $static: boolean }>`
  --card-0: ${({ $static }) => ($static ? 1 : 0)};
  --card-1: ${({ $static }) => ($static ? 1 : 0)};
  padding: 120px 24px 140px;
  background: linear-gradient(#fff9ef, #f8e5d8 70%, #ffc8a8aa);
  overflow: hidden;
  @media (max-width: 650px) {
    padding: 80px 16px 90px;
  }
`;
export const Intro = styled.div`
  text-align: center;
  max-width: 760px;
  margin: 0 auto 90px;
  @media (max-width: 650px) {
    margin-bottom: 60px;
  }
`;
export const Cards = styled.div`
  display: grid;
  grid-template-columns: repeat(2, minmax(0, 400px));
  justify-content: center;
  gap: 40px;
  @media (max-width: 850px) {
    grid-template-columns: minmax(0, 420px);
    gap: 70px;
  }
`;
export const Card = styled.article`
  position: relative;
  padding: 0 28px 30px;
  border-radius: 28px;
  background: #fffcf7;
  box-shadow: 0 30px 70px #173f3522;
  opacity: var(--in);
  transform: translateY(calc((1 - var(--in)) * 140px))
    rotate(calc(var(--dir) * (1 - var(--in)) * 9deg));
  transition: box-shadow 0.3s;
  &:hover {
    box-shadow: 0 36px 80px #173f3533;
  }
  blockquote {
    margin: 0;
  }
  p {
    font-size: 21px;
    line-height: 1.3 !important;
    letter-spacing: -0.6px;
    font-weight: 700;
    color: #171a18;
  }
  footer {
    margin-top: 18px;
    opacity: clamp(0, calc(var(--in) * 3 - 2), 1);
  }
  [data-signature] {
    display: block;
    font-family: Caveat;
    font-size: 38px;
    line-height: 1;
    color: #bd3448;
    rotate: -4deg;
    width: max-content;
  }
  cite {
    display: block;
    margin-top: 10px;
    font-style: normal;
    font-size: 13px;
    color: #686b67;
  }
`;
export const Portrait = styled.div`
  height: 250px;
  margin: 0 -28px 26px;
  border-radius: 28px 28px 0 0;
  overflow: hidden;
  display: grid;
  place-items: center;
  background:
    radial-gradient(60% 60% at 30% 25%, #ffc8a8, transparent 70%),
    linear-gradient(135deg, #f8e5d8, #ffb0b9);
  img {
    width: 100%;
    height: 100%;
    object-fit: cover;
  }
  span {
    font-family: "DM Serif", serif;
    font-size: 150px;
    line-height: 1;
    color: #173f35;
    transform: translateY(calc((1 - var(--in)) * 40px))
      scale(calc(0.8 + 0.2 * var(--in)));
  }
`;
