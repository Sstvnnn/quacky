class MockConfig {
  static const bool mockTts = false;

  static const int geminiWindowSeconds = 60;

  static const int consensusNeeded = 3;
  static const int consensusPool = 5;

  static const String alarmAsset = 'audio/quacky_sound.mp3';
  static const String geminiFeedAsset = 'assets/images/gemini_live_vids.mp4';

  static const List<(int, String)> geminiScript = [
    (2, 'I can see your surroundings. Stay calm, I am with you.'),
    (8, 'You are indoors. Move away from the window on your left.'),
    (16, 'There is a sturdy table ahead — get under it and cover your head.'),
    (26, 'I can see debris near the doorway. Do not try to leave yet.'),
    (38, 'You are doing well. Keep holding on, the shaking will pass.'),
    (50, 'If you are secure, tap I\'M SAFE. If you need help, tap SOS.'),
  ];

  static const String geminiContextSummary =
      '2nd-floor bedroom. Partial ceiling collapse — heavy debris on the '
      'floor, shattered window on the north wall. Doorway partially blocked. '
      'Subject responsive.';
}
