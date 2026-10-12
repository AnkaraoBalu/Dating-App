import styled from "styled-components";

// Optional scroll input from a parent: --msgs (0→1, default 1) brings messages in one by one.
// Message i is shown once --msgs * (count + 1) passes i.
export const Phone = styled.div`
  width: 100%;
  max-width: 370px;
  margin: auto;
  background: #fffcf7;
  color: #173f35;
  border: 1px solid #e5ddd3;
  border-radius: 30px;
  box-shadow: 0 24px 60px #173f3515;
  overflow: hidden;
  header {
    padding: 18px 20px;
    display: flex;
    align-items: center;
    gap: 12px;
    border-bottom: 1px solid #e5ddd3;
  }
  header img {
    width: 42px;
    height: 42px;
    object-fit: cover;
    border-radius: 50%;
  }
  header strong {
    font-size: 15px;
  }
  header p {
    position: relative;
    font-size: 11px;
    color: #686b67;
    line-height: 1.4;
  }
  /* "typing…" while messages are still arriving, then the usual subtitle. */
  [data-typing] {
    position: absolute;
    color: #bd3448;
    font-weight: 700;
    opacity: clamp(0, calc((1 - var(--msgs, 1)) * 8), 1);
  }
  [data-online] {
    opacity: clamp(0, calc(var(--msgs, 1) * 8 - 7), 1);
  }
  [data-body] {
    padding: 22px 18px;
    min-height: 270px;
  }
  [data-msg] {
    --in: clamp(0, calc(var(--msgs, 1) * (var(--count) + 1) - var(--i)), 1);
    display: grid;
    grid-template-rows: 1fr;
    opacity: var(--in);
    transform: translateY(calc((1 - var(--in)) * 18px))
      scale(calc(0.92 + 0.08 * var(--in)));
    transition:
      grid-template-rows 0.5s ease 0.15s,
      opacity 0.4s,
      filter 0.4s;
  }
  [data-msg] > div {
    min-height: 0;
    overflow: hidden;
    display: flex;
    flex-direction: column;
    padding-bottom: 10px;
  }
  [data-from="them"] {
    transform-origin: left bottom;
  }
  [data-from="me"] > div {
    align-items: flex-end;
  }
  [data-msg] button {
    max-width: 82%;
    padding: 13px 15px;
    border: 2px solid transparent;
    font-size: 13px;
    line-height: 1.45;
    text-align: left;
    color: inherit;
    cursor: pointer;
    transition:
      border-color 0.2s,
      transform 0.2s;
  }
  [data-msg] button:hover:not(:disabled) {
    transform: translateY(-2px);
  }
  [data-from="them"] button {
    border-radius: 16px 16px 16px 3px;
    background: #f4ece2;
  }
  [data-from="me"] button {
    border-radius: 16px 16px 3px 16px;
    background: #173f35;
    color: #fff9ef;
  }
  [data-msg] button[aria-pressed="true"] {
    border-color: #ff6678;
  }
  [data-msg] small {
    margin-top: 5px;
    font-size: 10px;
    font-weight: 800;
    color: #bd3448;
    animation: appear 0.3s;
  }
  [data-gone="true"] {
    grid-template-rows: 0fr;
    opacity: 0;
    filter: blur(6px);
  }
  [data-empty] {
    color: #686b67;
    font-size: 13px;
    padding: 20px 0;
    animation: appear 0.4s 0.4s both;
  }
  footer {
    padding: 18px 20px;
    border-top: 1px solid #e5ddd3;
  }
  [data-leave] {
    border: 1px solid #173f35;
    border-radius: 99px;
    padding: 10px 16px;
    background: transparent;
    color: #173f35;
    font-size: 12px;
    font-weight: 700;
  }
  footer p {
    font-size: 12px;
    margin-top: 12px;
    color: #173f35;
  }
  footer small {
    display: block;
    margin-top: 4px;
    font-size: 10px;
    color: #686b67;
  }
`;
