class MockConfig {
  static const int geminiWindowSeconds = 60;

  static const String alarmAsset = 'audio/quacky_sound.mp3';
  static const String geminiFeedAsset = 'assets/videos/gemini_live_vids.mp4';

  static const String magnitude = '6.0';

  static const int consensusNeeded = 50;
  static const int consensusReached = 52;
  static const double consensusRadiusKm = 5;
  static const int consensusWindowSeconds = 3;

  static const List<(int, String)> geminiAnalysis = [
    (1, 'Analyzing your surroundings…'),
    (5, 'Indoor environment detected — bedroom, 2nd floor.'),
    (11, 'Hazard: shattered window on your left. Keep clear.'),
    (18, 'Sturdy table ahead — take cover beneath it now.'),
    (27, 'Debris blocking the doorway. Do not exit yet.'),
    (38, 'You are doing well. Hold your position.'),
    (50, 'Tap I\'M SAFE if secure — or SOS to call for help.'),
  ];

  static const String voiceOverrideTranscript =
      'I am trapped under the stairs on the second floor, near the back door.';

  static const String geminiContextSummary =
      '2nd-floor bedroom. Partial ceiling collapse — heavy debris on the '
      'floor, shattered window on the north wall. Doorway partially blocked. '
      'Subject responsive.';

  static const String bimaContextSummary =
      'Ground-floor classroom, near the toy shelves by the east wall. '
      'Toppled cabinet blocking the exit route. Subject is a child, '
      'crying but responsive and visibly uninjured.';
}
