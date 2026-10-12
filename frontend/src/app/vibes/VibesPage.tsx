import { AppCta } from "../../components/app-cta";
import { VibesHero } from "./components/vibes-hero";
import { RoomsExplorer } from "./components/rooms-explorer";
import { InsideRoom } from "./components/inside-room";
import { IcebreakerMarquee } from "./components/icebreaker-marquee";
export function VibesPage() {
  return (
    <>
      <VibesHero />
      <RoomsExplorer />
      <InsideRoom />
      <IcebreakerMarquee />
      <AppCta />
    </>
  );
}
