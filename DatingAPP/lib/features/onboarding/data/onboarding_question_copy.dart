/// Copy and progress labels for the onboarding questions.
abstract final class OnboardingQuestionCopy {
  static const basicsStepCount = 3;
  static const vibeStepCount = 10;
  static const completedTitle = 'All set!\nNow let’s build your profile';
  static const completedSubtitle =
      'Your Matchify vibe is ready. Add a few profile details and let your personality shine.';
  static const createProfile = 'Create my profile';
  static const savedDialogTitle = 'Your vibe is saved';
  static const savedDialogMessage =
      'Your answers are ready. Add your profile photos and bio next to start meeting your kind of people.';
  static const dialogDismiss = 'Sounds good';

  static const titles = [
    'Let’s start with you',
    'Your gender identity',
    'Who are you interested in?',
    'Let’s find your vibe',
    'What’s your energy?',
    'Pick your ideal Friday',
    'Choose up to 5 things you love',
    'What’s your music taste?',
    'What’s your current era?',
    'Anything you won’t compromise on?',
    'Your dating intentions',
    'Where would you like to meet people?',
    'All set! Here’s your vibe',
  ];

  static String subtitle(int step, int selectedInterests) => switch (step) {
    0 => 'Add your name and birthday. You must be 18 or older.',
    1 => 'Choose what feels right for you.',
    2 => 'We’ll use this to personalize who you see.',
    3 => 'Answer a few fun questions to get better matches.',
    4 => 'Pick the energy that feels most like you.',
    5 => 'Which Friday sounds most like your kind of night?',
    6 =>
      'Pick activities you genuinely enjoy. $selectedInterests of 5 selected.',
    7 => 'Select up to 5 genres or artists you love.',
    8 => 'What chapter of life are you in right now?',
    9 =>
      'Choose the values and lifestyle choices that matter to you. Pick up to 8.',
    10 => 'What are you looking for?',
    11 => 'Choose a preferred distance. You can change it later.',
    _ => 'Tap the pencil to edit any answer before you finish.',
  };

  static String buttonLabel(int step) => switch (step) {
    3 => 'Let’s start',
    12 => 'Find my people ✨',
    _ => 'Continue',
  };
}
