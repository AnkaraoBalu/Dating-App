import type { ReactNode } from "react";
import { CommonContainer } from "../common-container";
import { Eyebrow } from "../ui";
import { Reveal } from "../reveal";
import { Hero } from "./PageHero.styles";
export function PageHero({
  eyebrow,
  title,
  description,
  center = true,
}: {
  eyebrow: string;
  title: ReactNode;
  description: string;
  center?: boolean;
}) {
  return (
    <Hero $center={center}>
      <CommonContainer>
        <Reveal>
          <Eyebrow>{eyebrow}</Eyebrow>
          <h1>{title}</h1>
          <p>{description}</p>
        </Reveal>
      </CommonContainer>
    </Hero>
  );
}
