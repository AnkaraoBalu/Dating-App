import { JourneyHero } from "./components/journey-hero";
import { StoryJourney } from "../../components/story-journey";
import { CommonContainer } from "../../components";
import {
  Section,
  Heading,
  Eyebrow,
  Actions,
  TextLink,
} from "../../components/ui";
import { AppCta } from "../../components/app-cta";
import { Detail } from "./HowItWorksPage.styles";
export function HowItWorksPage() {
  return (
    <>
      <JourneyHero />
      <StoryJourney nextTarget="details" />
      <Section id="details" tabIndex={-1}>
        <CommonContainer>
          <Eyebrow>The details that make a difference</Eyebrow>
          <Heading>
            Your connection.
            <br />
            <em>Your own pace.</em>
          </Heading>
          <Actions />
          <Detail>
            <span>01</span>
            <h3>Start with your story.</h3>
            <p>
              Add photos, prompts, and interests. Your profile gives someone a
              glimpse of the person behind the picture.
            </p>
          </Detail>
          <Detail>
            <span>02</span>
            <h3>More ways to meet.</h3>
            <p>
              Use Discover to browse profiles and filters. Explore Vibe rooms to
              connect through a shared interest.
            </p>
          </Detail>
          <Detail>
            <span>03</span>
            <h3>A match means a mutual yes.</h3>
            <p>
              Like someone who interests you. When they like you back, it
              becomes a match and you can open a conversation.
            </p>
          </Detail>
          <Detail>
            <span>04</span>
            <h3>Let the conversation happen.</h3>
            <p>
              Send a message or a photo. Viewed messages can disappear after the
              recipient leaves; saved messages remain for both people.
            </p>
          </Detail>
          <Actions>
            <TextLink to="/help">Still curious? Visit Help →</TextLink>
          </Actions>
        </CommonContainer>
      </Section>
      <AppCta />
    </>
  );
}
