import { StoryHero } from "./components/story-hero";
import { BeliefStatement } from "./components/belief-statement";
import { WelcomeGallery } from "./components/welcome-gallery";
import { Founders } from "./components/founders";
import { RealStories } from "./components/real-stories";
import { CommonContainer } from "../../components";
import {
  Section,
  Eyebrow,
  Heading,
  CardGrid,
  Feature,
} from "../../components/ui";
import { Reveal } from "../../components/reveal";
export function AboutPage() {
  return (
    <>
      <StoryHero />
      <BeliefStatement />
      <Section>
        <CommonContainer>
          <Reveal>
            <Eyebrow>What we’re here for</Eyebrow>
          </Reveal>
          <Reveal delay={0.12}>
            <Heading>
              Small things.
              <br />
              <em>Meaningful connections.</em>
            </Heading>
          </Reveal>
          <CardGrid>
            {[
              [
                "01",
                "Room for personality",
                "Profiles with photos, interests, and prompts that give you more to connect over.",
              ],
              [
                "02",
                "A shared starting point",
                "Discover someone new or follow a common interest into Vibes. Curiosity has plenty of places to go.",
              ],
              [
                "03",
                "A mutual beginning",
                "A conversation starts with a shared yes. You both choose to see where it goes.",
              ],
            ].map(([number, title, body], i) => (
              <Reveal key={number} delay={0.3 + i * 0.15}>
                <Feature>
                  <span>{number}</span>
                  <h3>{title}</h3>
                  <p>{body}</p>
                </Feature>
              </Reveal>
            ))}
          </CardGrid>
        </CommonContainer>
      </Section>
      <WelcomeGallery />
      <Founders />
      <RealStories />
    </>
  );
}
