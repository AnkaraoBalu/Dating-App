class VibeGamePlayer {
  const VibeGamePlayer({
    required this.id,
    required this.name,
    required this.avatar,
    required this.isHost,
    required this.hasAnswered,
    this.choiceIndex,
  });

  final String id;
  final String name;
  final String avatar;
  final bool isHost;
  final bool hasAnswered;
  final int? choiceIndex;

  factory VibeGamePlayer.fromJson(Map<String, dynamic> json) => VibeGamePlayer(
    id: json['id']?.toString() ?? '',
    name: json['name']?.toString() ?? 'Member',
    avatar: json['avatar']?.toString() ?? '',
    isHost: json['isHost'] == true,
    hasAnswered: json['hasAnswered'] == true,
    choiceIndex: (json['choiceIndex'] as num?)?.toInt(),
  );
}

class VibeGameQuestion {
  const VibeGameQuestion({required this.prompt, required this.options});

  final String prompt;
  final List<String> options;

  factory VibeGameQuestion.fromJson(Map<String, dynamic> json) =>
      VibeGameQuestion(
        prompt: json['prompt']?.toString() ?? '',
        options: (json['options'] as List<dynamic>? ?? const [])
            .map((option) => option.toString())
            .toList(),
      );
}

class VibeGameVote {
  const VibeGameVote({
    required this.userId,
    required this.name,
    required this.choiceIndex,
  });
  final String userId;
  final String name;
  final int choiceIndex;

  factory VibeGameVote.fromJson(Map<String, dynamic> json) => VibeGameVote(
    userId: json['userId']?.toString() ?? '',
    name: json['name']?.toString() ?? 'Member',
    choiceIndex: (json['choiceIndex'] as num?)?.toInt() ?? 0,
  );
}

class VibeGameRoundResult {
  const VibeGameRoundResult({
    required this.prompt,
    required this.options,
    required this.votes,
    this.correctChoiceIndex,
  });
  final String prompt;
  final List<String> options;
  final List<VibeGameVote> votes;
  final int? correctChoiceIndex;

  factory VibeGameRoundResult.fromJson(Map<String, dynamic> json) =>
      VibeGameRoundResult(
        prompt: json['prompt']?.toString() ?? '',
        options: (json['options'] as List<dynamic>? ?? const [])
            .map((e) => e.toString())
            .toList(),
        votes: (json['votes'] as List<dynamic>? ?? const [])
            .whereType<Map<String, dynamic>>()
            .map(VibeGameVote.fromJson)
            .toList(),
        correctChoiceIndex: (json['correctChoiceIndex'] as num?)?.toInt(),
      );
}

class VibeGameSession {
  const VibeGameSession({
    required this.id,
    required this.roomId,
    required this.gameType,
    required this.title,
    required this.status,
    required this.hostId,
    required this.isHost,
    required this.isParticipant,
    required this.questionIndex,
    required this.questionCount,
    required this.players,
    required this.playerCount,
    required this.answeredCount,
    required this.allAnswered,
    required this.createdAt,
    required this.results,
    this.secondsRemaining,
    this.question,
    this.myChoiceIndex,
  });

  final String id;
  final String roomId;
  final String gameType;
  final String title;
  final String status;
  final String hostId;
  final bool isHost;
  final bool isParticipant;
  final int questionIndex;
  final int questionCount;
  final List<VibeGamePlayer> players;
  final int playerCount;
  final int answeredCount;
  final bool allAnswered;
  final String createdAt;
  final int? secondsRemaining;
  final List<VibeGameRoundResult> results;
  final VibeGameQuestion? question;
  final int? myChoiceIndex;

  bool get isWaiting => status == 'waiting';
  bool get isPlaying => status == 'playing';
  bool get isCompleted => status == 'completed';

  factory VibeGameSession.fromJson(Map<String, dynamic> json) {
    final rawQuestion = json['question'];
    return VibeGameSession(
      id: json['id']?.toString() ?? '',
      roomId: json['roomId']?.toString() ?? '',
      gameType: json['gameType']?.toString() ?? '',
      title: json['title']?.toString() ?? 'Room game',
      status: json['status']?.toString() ?? 'waiting',
      hostId: json['hostId']?.toString() ?? '',
      isHost: json['isHost'] == true,
      isParticipant: json['isParticipant'] == true,
      questionIndex: (json['questionIndex'] as num?)?.toInt() ?? 0,
      questionCount: (json['questionCount'] as num?)?.toInt() ?? 0,
      players: (json['players'] as List<dynamic>? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(VibeGamePlayer.fromJson)
          .toList(),
      playerCount: (json['playerCount'] as num?)?.toInt() ?? 0,
      answeredCount: (json['answeredCount'] as num?)?.toInt() ?? 0,
      allAnswered: json['allAnswered'] == true,
      createdAt: json['createdAt']?.toString() ?? '',
      secondsRemaining: (json['secondsRemaining'] as num?)?.toInt(),
      results: (json['results'] as List<dynamic>? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(VibeGameRoundResult.fromJson)
          .toList(),
      question: rawQuestion is Map<String, dynamic>
          ? VibeGameQuestion.fromJson(rawQuestion)
          : null,
      myChoiceIndex: (json['myChoiceIndex'] as num?)?.toInt(),
    );
  }
}
