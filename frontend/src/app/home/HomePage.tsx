import { HomeHero } from "./components/home-hero";
import { HomeIntro } from "./components/home-intro";
import { StoryJourney } from "../../components/story-journey";
import { HomeMatch } from "./components/home-match";
import { HomeChat } from "./components/home-chat";
import { HomeFinale } from "./components/home-finale";
import * as S from "./HomePage.styles";
export function HomePage() {
  return (
    <S.Page>
      <HomeHero />
      <HomeIntro />
      <StoryJourney nextTarget="matching" />
      <HomeMatch />
      <HomeChat />
      <HomeFinale />
    </S.Page>
  );
}
