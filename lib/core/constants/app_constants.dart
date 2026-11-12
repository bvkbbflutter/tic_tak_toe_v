class AppConstants {
  static const String appName = "Tic Tac Toe";
  static const int turnTimeLimitSeconds = 20;

  // Pre-configured avatars for Web, Android, iOS that work offline & online without CORS issues
  static const List<String> presetAvatars = [
    'https://api.dicebear.com/7.x/bottts/png?seed=Rocket',
    'https://api.dicebear.com/7.x/bottts/png?seed=Cosmo',
    'https://api.dicebear.com/7.x/bottts/png?seed=Pixel',
    'https://api.dicebear.com/7.x/bottts/png?seed=Spark',
    'https://api.dicebear.com/7.x/bottts/png?seed=Nova',
    'https://api.dicebear.com/7.x/bottts/png?seed=Cyber',
    'https://api.dicebear.com/7.x/bottts/png?seed=Shadow',
    'https://api.dicebear.com/7.x/bottts/png?seed=Blaze',
  ];

  static const List<String> quickReactions = [
    '😂',
    '😎',
    '🔥',
    '👏',
    '😮',
    '😢',
    '❤️',
    '👍',
    '🎯',
    '⚡',
  ];

  static const List<String> quickMessages = [
    'Good game!',
    'Well played!',
    'Your turn!',
    'Nice move!',
    'Rematch?',
    'Almost had you!',
  ];

  static const List<String> genderOptions = [
    'Prefer not to say',
    'Male',
    'Female',
    'Non-binary',
  ];
}
