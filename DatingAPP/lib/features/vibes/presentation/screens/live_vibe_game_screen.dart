import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../core/theme/theme.dart';
import '../../data/vibe_game_live_service.dart';
import '../../data/vibe_artwork.dart';
import '../../data/vibe_rooms_api.dart';
import '../../models/vibe_game.dart';
import '../../models/vibe_room.dart';
import '../widgets/vibe_room_widgets.dart';

class LiveVibeGameScreen extends StatefulWidget {
  const LiveVibeGameScreen({
    super.key,
    required this.room,
    required this.sessionId,
    required this.api,
  });

  final VibeRoom room;
  final String sessionId;
  final VibeRoomsApi api;

  @override
  State<LiveVibeGameScreen> createState() => _LiveVibeGameScreenState();
}

class _LiveVibeGameScreenState extends State<LiveVibeGameScreen> {
  VibeGameSession? _session;
  VibeGameLiveService? _live;
  StreamSubscription<VibeGameChange>? _changes;
  Timer? _refreshTimer;
  Timer? _countdownTimer;
  DateTime? _roundDeadline;
  int _requestVersion = 0;
  bool _refreshing = false;
  bool _refreshPending = false;
  bool _loading = true;
  bool _busy = false;
  bool _leaving = false;
  String? _error;
  String? _syncError;

  @override
  void initState() {
    super.initState();
    final live = VibeGameLiveService(api: widget.api, roomId: widget.room.id);
    _live = live;
    _changes = live.changes.listen((change) {
      if (change.sessionId.isEmpty || change.sessionId == widget.sessionId) {
        unawaited(_refresh());
      }
    });
    live.live.addListener(_connectionChanged);
    live.connect();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted && _session?.isPlaying == true) setState(() {});
    });
    // The server's round deadline advances even if a player disconnects.
    // Polling also recovers if the socket is temporarily unavailable.
    _refreshTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      unawaited(_refresh());
    });
    unawaited(_refresh());
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _countdownTimer?.cancel();
    _live?.live.removeListener(_connectionChanged);
    unawaited(_changes?.cancel());
    unawaited(_live?.dispose());
    super.dispose();
  }

  void _connectionChanged() {
    if (mounted) setState(() {});
  }

  void _applySession(VibeGameSession session) {
    _session = session;
    _roundDeadline = session.secondsRemaining == null
        ? null
        : DateTime.now().add(Duration(seconds: session.secondsRemaining!));
    _loading = false;
  }

  int get _secondsRemaining {
    final deadline = _roundDeadline;
    if (deadline == null) return 0;
    final milliseconds = deadline.difference(DateTime.now()).inMilliseconds;
    return milliseconds <= 0 ? 0 : (milliseconds / 1000).ceil();
  }

  Future<void> _refresh() async {
    if (!mounted || _leaving) return;
    if (_busy || _refreshing) {
      _refreshPending = true;
      return;
    }
    _refreshing = true;
    _refreshPending = false;
    final version = _requestVersion;
    try {
      final session = await widget.api.getGame(
        widget.room.id,
        widget.sessionId,
      );
      if (!mounted || version != _requestVersion) return;
      setState(() {
        _applySession(session);
        _syncError = null;
      });
    } catch (_) {
      if (!mounted || version != _requestVersion) return;
      setState(() {
        _loading = false;
        _syncError =
            'Could not sync the game. Check your connection and retry.';
      });
    } finally {
      _refreshing = false;
      if (mounted && _refreshPending && !_busy) unawaited(_refresh());
    }
  }

  Future<void> _perform(
    Future<VibeGameSession> Function() action, {
    bool closeAfter = false,
  }) async {
    if (_busy || !mounted || _leaving) return;
    _requestVersion++;
    var refreshAfter = false;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final session = await action();
      if (!mounted) return;
      if (closeAfter) {
        setState(() => _leaving = true);
        await WidgetsBinding.instance.endOfFrame;
        if (!mounted) return;
        Navigator.of(context).pop();
      } else {
        setState(() => _applySession(session));
      }
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = _messageFor(error));
      refreshAfter = true;
    } finally {
      if (mounted) setState(() => _busy = false);
    }
    if ((refreshAfter || _refreshPending) && mounted) await _refresh();
  }

  String _messageFor(Object error) {
    final value = error.toString();
    if (value.contains('Wait for at least one other player')) {
      return 'At least two players need to join before the host can start.';
    }
    if (value.contains('full')) return 'This game is full.';
    if (value.contains('already locked')) {
      return 'Your answer is locked. Waiting for the room…';
    }
    if (value.contains('question has changed')) {
      return 'The next question is ready.';
    }
    return 'That action did not go through. Please try again.';
  }

  @override
  Widget build(BuildContext context) {
    final session = _session;
    return PopScope<Object?>(
      canPop:
          _leaving ||
          session?.isCompleted == true ||
          session?.status == 'cancelled',
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop &&
            session?.isCompleted != true &&
            session?.status != 'cancelled') {
          unawaited(_leaveGame());
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.background,
          foregroundColor: AppColors.textPrimary,
          title: Text(
            session?.title ?? 'Room game',
            style: AppTypography.h3.copyWith(color: AppColors.textPrimary),
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Center(
                child: _ConnectionLabel(live: _live?.live.value ?? false),
              ),
            ),
          ],
        ),
        body: SafeArea(
          top: false,
          child: _loading && session == null
              ? const Center(child: CircularProgressIndicator())
              : session == null
              ? _LoadError(error: _error ?? _syncError, onRetry: _refresh)
              : ListView(
                  padding: const EdgeInsets.fromLTRB(18, 8, 18, 22),
                  children: [
                    if (_error != null || _syncError != null) ...[
                      _InlineError(
                        text: (_error ?? _syncError)!,
                        onRetry: () {
                          setState(() => _error = null);
                          unawaited(_refresh());
                        },
                      ),
                      const SizedBox(height: 12),
                    ],
                    if (session.isWaiting) _lobby(session),
                    if (session.isPlaying) _playing(session),
                    if (session.isCompleted) _results(session),
                    if (session.status == 'cancelled') _cancelled(),
                  ],
                ),
        ),
        bottomNavigationBar:
            session == null ||
                session.isCompleted ||
                session.status == 'cancelled'
            ? null
            : SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(18, 5, 18, 10),
                  child: TextButton.icon(
                    onPressed: _busy ? null : _leaveGame,
                    icon: const Icon(Icons.exit_to_app_rounded),
                    label: const Text('Leave game'),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.textSecondary,
                    ),
                  ),
                ),
              ),
      ),
    );
  }

  Future<void> _leaveGame() async {
    if (_busy || _leaving) return;
    final session = _session;
    if (session?.isHost == true &&
        (session!.gameType == 'guess_my_vibe' ||
            session.gameType == 'two_truths_and_a_lie')) {
      final leave = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('End this game?'),
          content: const Text(
            'This game is about you. Leaving will end it for everyone.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Keep playing'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('End game'),
            ),
          ],
        ),
      );
      if (leave != true || !mounted) return;
    }
    await _perform(
      () => widget.api.leaveGame(widget.room.id, widget.sessionId),
      closeAfter: true,
    );
  }

  Widget _lobby(VibeGameSession session) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      _StepProgress(index: 0, total: session.questionCount),
      const SizedBox(height: 24),
      const Text(
        'Waiting room',
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
      ),
      const SizedBox(height: 7),
      Text(
        session.isHost
            ? 'People in ${widget.room.title} can join this game. Start when at least one other player is ready.'
            : 'You joined ${widget.room.title}. The host will start when ready.',
        textAlign: TextAlign.center,
        style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
      ),
      const SizedBox(height: 22),
      _Panel(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Players',
                    style: AppTypography.title.copyWith(
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                Text(
                  '${session.playerCount}/8',
                  style: AppTypography.label.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 13),
            for (final player in session.players)
              Padding(
                padding: const EdgeInsets.only(bottom: 11),
                child: Row(
                  children: [
                    VibeRoomAvatar(image: player.avatar, size: 40),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        player.name,
                        style: AppTypography.label.copyWith(
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    if (player.isHost) _Pill(text: 'HOST'),
                    if (!player.isHost) _Pill(text: 'READY'),
                  ],
                ),
              ),
            if (session.playerCount < 8)
              Text(
                'Waiting for more players to join…',
                style: AppTypography.caption.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
          ],
        ),
      ),
      const SizedBox(height: 18),
      if (session.isHost)
        FilledButton(
          onPressed: _busy || session.playerCount < 2
              ? null
              : () => _perform(
                  () => widget.api.startGame(widget.room.id, session.id),
                ),
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.coral,
            foregroundColor: Colors.white,
            minimumSize: const Size.fromHeight(52),
          ),
          child: Text(
            _busy
                ? 'Starting…'
                : session.playerCount < 2
                ? 'Waiting for one more player'
                : 'Start game',
          ),
        )
      else
        const _Notice(
          text:
              'The host will start the game when at least two people are ready.',
        ),
    ],
  );

  Widget _playing(VibeGameSession session) {
    final question = session.question;
    if (question == null || question.options.length < 2) {
      return _LoadError(
        error: 'This round could not be loaded.',
        onRetry: _refresh,
      );
    }
    final selected = session.myChoiceIndex;
    final choiceImages = VibeArtwork.forChoices(
      session.gameType,
      question.options,
    );
    final remaining = _secondsRemaining;
    final canAnswer = selected == null && !_busy && remaining > 0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _StepProgress(
          index: session.questionIndex + 1,
          total: session.questionCount,
        ),
        const SizedBox(height: 9),
        Row(
          children: [
            Expanded(
              child: Text(
                'Question ${session.questionIndex + 1} of ${session.questionCount}',
                style: AppTypography.caption.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ),
            Text(
              remaining == 0 ? 'Syncing next round…' : '${remaining}s',
              style: AppTypography.label.copyWith(
                color: remaining <= 10
                    ? AppColors.coral
                    : AppColors.textSecondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 17),
        _PlayerStrip(players: session.players),
        const SizedBox(height: 19),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 17, vertical: 19),
          decoration: BoxDecoration(
            color: AppColors.peachSoft,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Text(
            question.prompt,
            textAlign: TextAlign.center,
            style: AppTypography.title.copyWith(
              color: AppColors.textPrimary,
              fontSize: 17,
            ),
          ),
        ),
        if (session.gameType == 'guess_my_vibe') ...[
          const SizedBox(height: 8),
          Text(
            session.isHost
                ? 'Host: choose what you would really pick.'
                : 'Guess which option the host would choose.',
            textAlign: TextAlign.center,
            style: AppTypography.caption.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
        const SizedBox(height: 13),
        if (session.gameType == 'two_truths_and_a_lie' && session.isHost)
          const _Notice(
            text:
                'You set the lie. Players are guessing now—keep it secret until the results!',
          )
        else if (choiceImages != null && question.options.length == 2)
          LayoutBuilder(
            builder: (context, constraints) {
              final cards = [
                for (var index = 0; index < question.options.length; index++)
                  _AnswerCard(
                    label: question.options[index],
                    image: choiceImages[index],
                    selected: selected == index,
                    disabled: !canAnswer,
                    choice: index,
                    onTap: () => _answer(session, index),
                  ),
              ];
              if (constraints.maxWidth < 320 ||
                  MediaQuery.textScalerOf(context).scale(15) > 22) {
                return Column(
                  children: [
                    cards.first,
                    const SizedBox(height: 10),
                    cards.last,
                  ],
                );
              }
              return IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(child: cards.first),
                    const SizedBox(width: 10),
                    Expanded(child: cards.last),
                  ],
                ),
              );
            },
          )
        else
          for (var index = 0; index < question.options.length; index++) ...[
            _AnswerCard(
              label: question.options[index],
              selected: selected == index,
              disabled: !canAnswer,
              choice: index,
              onTap: () => _answer(session, index),
            ),
            const SizedBox(height: 10),
          ],
        const SizedBox(height: 6),
        if (selected != null)
          _Notice(
            text: session.allAnswered
                ? 'Everyone answered. Moving to the next question…'
                : 'Your answer is locked. ${session.answeredCount} of ${session.gameType == 'two_truths_and_a_lie' ? session.playerCount - 1 : session.playerCount} players answered.',
          ),
        if (selected == null &&
            !(session.gameType == 'two_truths_and_a_lie' && session.isHost))
          Text(
            'Your choice stays private until the game results.',
            textAlign: TextAlign.center,
            style: AppTypography.caption.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
      ],
    );
  }

  Future<void> _answer(VibeGameSession session, int choiceIndex) => _perform(
    () => widget.api.answerGame(
      roomId: widget.room.id,
      sessionId: session.id,
      questionIndex: session.questionIndex,
      choiceIndex: choiceIndex,
    ),
  );

  Widget _results(VibeGameSession session) {
    final resultRows = session.results;
    final matches = _matchingAnswers(session);
    final scoredRounds = session.gameType == 'guess_my_vibe'
        ? resultRows.where(
            (round) => round.votes.any((vote) => vote.userId == session.hostId),
          )
        : resultRows;
    final possibleMatches =
        session.gameType == 'guess_my_vibe' ||
            session.gameType == 'two_truths_and_a_lie'
        ? scoredRounds.fold<int>(
            0,
            (sum, round) =>
                sum +
                round.votes
                    .where((vote) => vote.userId != session.hostId)
                    .length,
          )
        : resultRows.where((round) => round.votes.length > 1).length;
    final summary = session.gameType == 'guess_my_vibe'
        ? '$matches of $possibleMatches guesses matched the host.'
        : session.gameType == 'two_truths_and_a_lie'
        ? '$matches of $possibleMatches players guessed the lie.'
        : '$matches of $possibleMatches rounds had matching choices across the room.';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 12),
        const Icon(Icons.celebration_rounded, size: 48, color: AppColors.coral),
        const SizedBox(height: 8),
        Text(
          'That was the game!',
          textAlign: TextAlign.center,
          style: AppTypography.h2.copyWith(color: AppColors.textPrimary),
        ),
        const SizedBox(height: 5),
        Text(
          summary,
          textAlign: TextAlign.center,
          style: AppTypography.bodySmall.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 17),
        _PlayerStrip(players: session.players),
        const SizedBox(height: 20),
        for (final result in resultRows) ...[
          _Panel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  result.prompt,
                  style: AppTypography.label.copyWith(
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 10),
                for (var i = 0; i < result.options.length; i++)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      children: [
                        _roundChoiceThumb(session.gameType, result.options, i),
                        Icon(
                          Icons.circle,
                          size: 9,
                          color: _countVotes(result.votes, i) == 0
                              ? AppColors.border
                              : AppColors.coral,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            result.options[i],
                            style: AppTypography.bodySmall.copyWith(
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                        if (result.correctChoiceIndex == i)
                          const Icon(
                            Icons.check_circle,
                            color: AppColors.success,
                            size: 16,
                          ),
                        const SizedBox(width: 5),
                        Text(
                          '${_countVotes(result.votes, i)}',
                          style: AppTypography.label.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                if (result.votes.isNotEmpty)
                  Text(
                    result.votes
                        .map(
                          (vote) =>
                              '${vote.name}: ${result.options[vote.choiceIndex]}',
                        )
                        .join('  ·  '),
                    style: AppTypography.caption.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 9),
        ],
        const SizedBox(height: 12),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(),
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.coral,
            foregroundColor: Colors.white,
            minimumSize: const Size.fromHeight(50),
          ),
          child: const Text('Back to room games'),
        ),
      ],
    );
  }

  Widget _roundChoiceThumb(
    String gameType,
    List<String> options,
    int choiceIndex,
  ) {
    final images = VibeArtwork.forChoices(gameType, options);
    if (images == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: Image.asset(
          images[choiceIndex],
          width: 52,
          height: 36,
          fit: BoxFit.cover,
          excludeFromSemantics: true,
        ),
      ),
    );
  }

  int _matchingAnswers(VibeGameSession session) {
    var matches = 0;
    for (final round in session.results) {
      if (session.gameType == 'two_truths_and_a_lie') {
        if (round.correctChoiceIndex == null) continue;
        matches += round.votes
            .where(
              (vote) =>
                  vote.userId != session.hostId &&
                  vote.choiceIndex == round.correctChoiceIndex,
            )
            .length;
      } else if (session.gameType == 'guess_my_vibe') {
        final hostVotes = round.votes
            .where((vote) => vote.userId == session.hostId)
            .toList();
        if (hostVotes.isNotEmpty) {
          final hostVote = hostVotes.first;
          matches += round.votes
              .where(
                (vote) =>
                    vote.userId != session.hostId &&
                    vote.choiceIndex == hostVote.choiceIndex,
              )
              .length;
        }
      } else if (round.votes.length > 1 &&
          round.votes.every(
            (vote) => vote.choiceIndex == round.votes.first.choiceIndex,
          )) {
        matches++;
      }
    }
    return matches;
  }

  int _countVotes(List<VibeGameVote> votes, int choiceIndex) =>
      votes.where((vote) => vote.choiceIndex == choiceIndex).length;

  Widget _cancelled() => const _Notice(
    text:
        'This game ended because the waiting room expired, everyone left, or its host left a game about them. Return to room games to start again.',
  );
}

class _PlayerStrip extends StatelessWidget {
  const _PlayerStrip({required this.players});
  final List<VibeGamePlayer> players;
  @override
  Widget build(BuildContext context) => Wrap(
    alignment: WrapAlignment.center,
    spacing: 11,
    runSpacing: 10,
    children: [
      for (final player in players)
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                VibeRoomAvatar(
                  image: player.avatar,
                  size: 43,
                  borderColor: player.hasAnswered
                      ? AppColors.success
                      : AppColors.surface,
                ),
                if (player.hasAnswered)
                  const Positioned(
                    right: -2,
                    bottom: -2,
                    child: Icon(
                      Icons.check_circle,
                      size: 16,
                      color: AppColors.success,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            SizedBox(
              width: 72,
              child: Text(
                player.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.caption.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          ],
        ),
    ],
  );
}

class _AnswerCard extends StatelessWidget {
  const _AnswerCard({
    required this.label,
    required this.selected,
    required this.disabled,
    required this.choice,
    required this.onTap,
    this.image,
  });
  final String label;
  final String? image;
  final bool selected;
  final bool disabled;
  final int choice;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Semantics(
    selected: selected,
    child: Material(
      color: selected ? AppColors.peachSoft : AppColors.surface,
      borderRadius: BorderRadius.circular(17),
      child: InkWell(
        onTap: disabled ? null : onTap,
        borderRadius: BorderRadius.circular(17),
        child: Container(
          constraints: const BoxConstraints(minHeight: 72),
          padding: EdgeInsets.symmetric(
            horizontal: image == null ? 16 : 9,
            vertical: 13,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(17),
            border: Border.all(
              color: selected ? AppColors.coral : AppColors.border,
              width: selected ? 2 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (image != null) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(11),
                  child: AspectRatio(
                    aspectRatio: 1.5,
                    child: Image.asset(
                      image!,
                      fit: BoxFit.cover,
                      excludeFromSemantics: true,
                      errorBuilder: (_, _, _) => const SizedBox.shrink(),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
              ],
              Row(
                children: [
                  if (image == null)
                    Container(
                      width: 30,
                      height: 30,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: selected
                            ? AppColors.coral
                            : AppColors.surfaceSecondary,
                      ),
                      child: Text(
                        String.fromCharCode(65 + choice),
                        style: AppTypography.label.copyWith(
                          color: selected
                              ? Colors.white
                              : AppColors.textSecondary,
                        ),
                      ),
                    ),
                  if (image == null) const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      label,
                      style: AppTypography.title.copyWith(
                        color: AppColors.textPrimary,
                        fontSize: 15,
                      ),
                    ),
                  ),
                  if (selected)
                    const Icon(
                      Icons.check_circle_rounded,
                      color: AppColors.coral,
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class _StepProgress extends StatelessWidget {
  const _StepProgress({required this.index, required this.total});
  final int index;
  final int total;
  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(12),
    child: LinearProgressIndicator(
      value: total == 0 ? 0 : index / total,
      minHeight: 7,
      backgroundColor: AppColors.surfaceSecondary,
      color: AppColors.coral,
    ),
  );
}

class _Panel extends StatelessWidget {
  const _Panel({required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(17),
      border: Border.all(color: AppColors.border),
    ),
    child: child,
  );
}

class _Notice extends StatelessWidget {
  const _Notice({required this.text});
  final String text;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(13),
    decoration: BoxDecoration(
      color: AppColors.peachSoft,
      borderRadius: BorderRadius.circular(14),
    ),
    child: Text(
      text,
      textAlign: TextAlign.center,
      style: AppTypography.bodySmall.copyWith(color: AppColors.textPrimary),
    ),
  );
}

class _InlineError extends StatelessWidget {
  const _InlineError({required this.text, required this.onRetry});
  final String text;
  final VoidCallback onRetry;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: AppColors.peachSoft,
      borderRadius: BorderRadius.circular(14),
    ),
    child: Row(
      children: [
        Expanded(
          child: Text(
            text,
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textPrimary,
            ),
          ),
        ),
        TextButton(onPressed: onRetry, child: const Text('Retry')),
      ],
    ),
  );
}

class _LoadError extends StatelessWidget {
  const _LoadError({required this.error, required this.onRetry});
  final String? error;
  final VoidCallback onRetry;
  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.wifi_off_rounded,
            size: 42,
            color: AppColors.textTertiary,
          ),
          const SizedBox(height: 10),
          Text(
            error ?? 'Could not load this game.',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          OutlinedButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    ),
  );
}

class _Pill extends StatelessWidget {
  const _Pill({required this.text});
  final String text;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(
      color: AppColors.peachSoft,
      borderRadius: BorderRadius.circular(20),
    ),
    child: Text(
      text,
      style: AppTypography.caption.copyWith(
        color: AppColors.coral,
        fontWeight: FontWeight.w800,
      ),
    ),
  );
}

class _ConnectionLabel extends StatelessWidget {
  const _ConnectionLabel({required this.live});
  final bool live;
  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(
        Icons.circle,
        size: 7,
        color: live ? AppColors.success : AppColors.textTertiary,
      ),
      const SizedBox(width: 5),
      Text(
        live ? 'LIVE' : 'SYNCING',
        style: AppTypography.caption.copyWith(
          color: AppColors.textSecondary,
          fontSize: 10,
        ),
      ),
    ],
  );
}
