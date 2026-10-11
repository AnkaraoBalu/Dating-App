import '../../../core/constants/app_assets.dart';
import '../models/welcome_slide.dart';

abstract final class WelcomeSlides {
  static const all = [
    WelcomeSlide(
      image: AppAssets.welcomePersonality,
      title: 'Find someone\nwho gets your weird.',
      description:
          'Dating beyond swipes.\nBased on personality, energy\nand the little things.',
      notes: ['Places', 'People', 'You?', 'Moments'],
    ),
    WelcomeSlide(
      image: AppAssets.welcomeEnergy,
      title: 'Same energy.\nDifferent stories.',
      description:
          'Your playlists. Your coffee order.\nYour kind of Friday night.\nFind someone on your wavelength.',
      notes: ['Music', 'Coffee', 'Your vibe', 'Little things'],
    ),
    WelcomeSlide(
      image: AppAssets.welcomeConnection,
      title: 'Less small talk.\nMore real connection.',
      description:
          'A shared laugh. An honest moment.\nMake room for something\nthat feels like you.',
      notes: ['Laughter', 'Together', 'Be you', 'Connection'],
    ),
    WelcomeSlide(
      image: AppAssets.welcomeNewChapter,
      title: 'Your next chapter\nstarts with a hello.',
      description:
          'Meet with intention.\nTake your time.\nLet a good thing grow.',
      notes: ['A hello', 'A spark', 'Your story', 'What next?'],
    ),
  ];
}
