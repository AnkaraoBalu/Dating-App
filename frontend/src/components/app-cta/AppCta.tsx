import { ButtonLink } from "../ui";
import { Reveal } from "../reveal";
import { Root } from "./AppCta.styles";
export function AppCta() {
  return (
    <Root>
      <Reveal>
        <span data-spark aria-hidden="true">
          ✳
        </span>
        <h2>
          Someone out there
          <br />
          gets <em>your kind of weird.</em>
        </h2>
        <p>
          Start with what makes you, you. See where a little curiosity can take
          you.
        </p>
        <ButtonLink to="/download">
          Meet Just2 <span aria-hidden="true">↗</span>
        </ButtonLink>
      </Reveal>
    </Root>
  );
}
