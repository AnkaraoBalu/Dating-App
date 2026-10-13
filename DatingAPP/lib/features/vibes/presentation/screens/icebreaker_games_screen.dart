import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../core/theme/theme.dart';
import '../../data/vibe_game_live_service.dart';
import '../../data/vibe_rooms_api.dart';
import '../../models/vibe_game.dart';
import '../../models/vibe_room.dart';
import '../widgets/vibe_room_list_widgets.dart';
import 'live_vibe_game_screen.dart';

class IcebreakerGamesScreen extends StatefulWidget {
  const IcebreakerGamesScreen({super.key, required this.room, this.api});

  final VibeRoom room;
  final VibeRoomsApi? api;

  @override
  State<IcebreakerGamesScreen> createState() => _IcebreakerGamesScreenState();
}

class _IcebreakerGamesScreenState extends State<IcebreakerGamesScreen> {
  static const _games = <(String, String, String, String)>[
    ('This or That', '💞', 'this_or_that', 'Quick preference rounds'),
    ('Red Flag / Green Flag', '🚩', 'red_flag_green_flag', 'Decide together'),
    ('Would You Rather?', '❔', 'would_you_rather', 'Pick your side'),
    ('Guess My Vibe', '💝', 'guess_my_vibe', 'Guess the host’s choices'),
    (
      'Two Truths and a Lie',
      '🫶',
      'two_truths_and_a_lie',
      'Compare your guesses',
    ),
    ('Chemistry Check', '💞', 'chemistry_check', 'Compare your answers'),
  ];

  VibeGameSession? _active;
  VibeGameLiveService? _live;
  StreamSubscription<VibeGameChange>? _changes;
  Timer? _refreshTimer;
  bool _refreshing = false;
  int _requestVersion = 0;
  bool _loading = true;
  bool _creating = false;
  String? _error;
  (String, String, String, String)? _setupGame;
  final _statementControllers = List.generate(
    3,
    (_) => TextEditingController(),
  );
  int _lieIndex = 0;

  @override
  void initState() {
    super.initState();
    final api = widget.api;
    if (api != null) {
      final live = VibeGameLiveService(api: api, roomId: widget.room.id);
      _live = live;
      _changes = live.changes.listen((_) => unawaited(_refresh()));
      live.connect();
      _refreshTimer = Timer.periodic(const Duration(seconds: 5), (_) {
        unawaited(_refresh());
      });
      unawaited(_refresh());
    } else {
      _loading = false;
      _error = 'Live games are unavailable. Reopen the room when connected.';
    }
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    for (final controller in _statementControllers) {
      controller.dispose();
    }
    unawaited(_changes?.cancel());
    unawaited(_live?.dispose());
    super.dispose();
  }

  Future<void> _refresh() async {
    final api = widget.api;
    if (api == null || !mounted || _refreshing) return;
    _refreshing = true;
    final version = _requestVersion;
    try {
      final game = await api.getActiveGame(widget.room.id);
      if (!mounted || version != _requestVersion) return;
      setState(() {
        _active = game;
        _loading = false;
        _error = null;
      });
    } catch (error) {
      if (!mounted || version != _requestVersion) return;
      setState(() {
        _loading = false;
        _error = 'Could not load live games. Check your connection and retry.';
      });
    } finally {
      _refreshing = false;
    }
  }

  Future<void> _play((String, String, String, String) game) async {
    final api = widget.api;
    if (api == null || _creating) return;
    if (_active != null) {
      await _openActive(join: !_active!.isParticipant);
      return;
    }
    if (game.$3 == 'two_truths_and_a_lie') {
      setState(() {
        _setupGame = game;
        _error = null;
      });
      return;
    }
    await _createGame(game);
  }

  Future<void> _createGame(
    (String, String, String, String) game, {
    Map<String, dynamic>? setup,
  }) async {
    final api = widget.api;
    if (api == null || _creating) return;
    setState(() {
      _creating = true;
      _error = null;
    });
    try {
      final session = await api.createGame(
        widget.room.id,
        game.$3,
        setup: setup,
      );
      if (!mounted) return;
      _requestVersion++;
      setState(() {
        _active = session;
        _setupGame = null;
      });
      await _openSession(session);
    } catch (_) {
      await _refresh();
      if (mounted && _active == null) {
        setState(() => _error = 'Could not start the game. Please try again.');
      }
    } finally {
      if (mounted) setState(() => _creating = false);
    }
  }

  Future<void> _submitTruthsSetup() async {
    final game = _setupGame;
    if (game == null) return;
    final statements = _statementControllers
        .map((controller) => controller.text.trim())
        .toList();
    if (statements.any((statement) => statement.isEmpty)) {
      setState(
        () => _error = 'Fill in all three statements before creating the game.',
      );
      return;
    }
    if (statements.toSet().length != 3 ||
        statements.map((s) => s.toLowerCase()).toSet().length != 3) {
      setState(() => _error = 'Use three different statements.');
      return;
    }
    await _createGame(
      game,
      setup: {'statements': statements, 'lieIndex': _lieIndex},
    );
  }

  Future<void> _openActive({required bool join}) async {
    final active = _active;
    final api = widget.api;
    if (active == null || api == null || _creating) return;
    setState(() => _creating = true);
    try {
      final session = join
          ? await api.joinGame(widget.room.id, active.id)
          : await api.getGame(widget.room.id, active.id);
      if (!mounted) return;
      await _openSession(session);
    } catch (error) {
      await _refresh();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              error.toString().contains('full')
                  ? 'This game is full. Try again when a player leaves.'
                  : 'Could not open this game. Check your connection and try again.',
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _creating = false);
    }
  }

  Future<void> _openSession(VibeGameSession session) async {
    final api = widget.api;
    if (api == null) return;
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => LiveVibeGameScreen(
          room: widget.room,
          sessionId: session.id,
          api: api,
        ),
      ),
    );
    if (mounted) await _refresh();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.background,
    appBar: AppBar(
      backgroundColor: AppColors.background,
      foregroundColor: AppColors.textPrimary,
      title: Text(
        'Break the ice ✨',
        style: AppTypography.h3.copyWith(color: AppColors.textPrimary),
      ),
    ),
    body: SafeArea(
      top: false,
      child: RefreshIndicator(
        onRefresh: _refresh,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(17, 8, 17, 28),
          children: [
            Text(
              'Play together with people in ${widget.room.title}.',
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              _StatusBanner(text: _error!, onRetry: _refresh),
            ],
            if (_loading) ...[
              const SizedBox(height: 16),
              const LinearProgressIndicator(),
            ],
            if (_active != null) ...[
              const SizedBox(height: 19),
              VibeRoomSectionTitle(title: 'Happening now'),
              const SizedBox(height: 9),
              _ActiveGameCard(
                session: _active!,
                busy: _creating,
                onTap: () => _openActive(join: !_active!.isParticipant),
              ),
            ],
            const SizedBox(height: 20),
            VibeRoomSectionTitle(
              title: _active == null ? 'Choose a game' : 'Other games',
            ),
            const SizedBox(height: 9),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _games.length,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: MediaQuery.sizeOf(context).width < 360 ? 1 : 2,
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                childAspectRatio: 1.06,
              ),
              itemBuilder: (context, index) => _GameTile(
                title: _games[index].$1,
                emoji: _games[index].$2,
                description: _games[index].$4,
                enabled:
                    widget.api != null &&
                    !_loading &&
                    !_creating &&
                    _active == null &&
                    _setupGame == null,
                onPlay: () => _play(_games[index]),
              ),
            ),
            if (_setupGame != null) ...[
              const SizedBox(height: 14),
              _TruthsSetup(
                controllers: _statementControllers,
                lieIndex: _lieIndex,
                busy: _creating,
                onLieChanged: (index) => setState(() => _lieIndex = index),
                onCancel: () => setState(() => _setupGame = null),
                onStart: _submitTruthsSetup,
              ),
            ],
            if (widget.api == null)
              Padding(
                padding: const EdgeInsets.only(top: 14),
                child: Text(
                  'Connect to the room to start a live game.',
                  textAlign: TextAlign.center,
                  style: AppTypography.caption.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
          ],
        ),
      ),
    ),
  );
}

class _ActiveGameCard extends StatelessWidget {
  const _ActiveGameCard({
    required this.session,
    required this.busy,
    required this.onTap,
  });
  final VibeGameSession session;
  final bool busy;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final label = switch (session.status) {
      'waiting' => 'Waiting for players',
      'playing' =>
        'Question ${session.questionIndex + 1} of ${session.questionCount}',
      _ => 'Game in progress',
    };
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: AppColors.coral, width: 1.4),
      ),
      child: Row(
        children: [
          const Text('🎮', style: TextStyle(fontSize: 30)),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  session.title,
                  style: AppTypography.label.copyWith(
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  '$label · ${session.playerCount} ${session.playerCount == 1 ? 'player' : 'players'}',
                  style: AppTypography.caption.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          FilledButton(
            onPressed: busy ? null : onTap,
            child: Text(
              busy
                  ? 'Opening…'
                  : session.isParticipant
                  ? 'Resume'
                  : 'Join',
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusBanner extends StatelessWidget {
  const _StatusBanner({required this.text, required this.onRetry});
  final String text;
  final VoidCallback onRetry;
  @override
  Widget build(BuildContext context) => Material(
    color: AppColors.peachSoft,
    borderRadius: BorderRadius.circular(14),
    child: Padding(
      padding: const EdgeInsets.all(12),
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
    ),
  );
}

class _GameTile extends StatelessWidget {
  const _GameTile({
    required this.title,
    required this.emoji,
    required this.description,
    required this.enabled,
    required this.onPlay,
  });
  final String title;
  final String emoji;
  final String description;
  final bool enabled;
  final VoidCallback onPlay;

  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(17),
      border: Border.all(color: AppColors.border),
    ),
    child: Padding(
      padding: const EdgeInsets.all(11),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Center(
              child: Text(emoji, style: const TextStyle(fontSize: 43)),
            ),
          ),
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.label.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            description,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.caption.copyWith(
              color: AppColors.textSecondary,
              fontSize: 10,
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            height: 36,
            child: FilledButton(
              onPressed: enabled ? onPlay : null,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.coral,
                foregroundColor: Colors.white,
                padding: EdgeInsets.zero,
              ),
              child: Text(enabled ? 'Start game' : 'Room busy'),
            ),
          ),
        ],
      ),
    ),
  );
}

class _TruthsSetup extends StatelessWidget {
  const _TruthsSetup({
    required this.controllers,
    required this.lieIndex,
    required this.busy,
    required this.onLieChanged,
    required this.onCancel,
    required this.onStart,
  });

  final List<TextEditingController> controllers;
  final int lieIndex;
  final bool busy;
  final ValueChanged<int> onLieChanged;
  final VoidCallback onCancel;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(15),
    decoration: BoxDecoration(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(17),
      border: Border.all(color: AppColors.coral),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Set up your round',
          style: AppTypography.title.copyWith(color: AppColors.textPrimary),
        ),
        const SizedBox(height: 4),
        Text(
          'Write two true facts and one lie. Players will guess the lie.',
          style: AppTypography.caption.copyWith(color: AppColors.textSecondary),
        ),
        const SizedBox(height: 11),
        for (var index = 0; index < controllers.length; index++) ...[
          TextField(
            controller: controllers[index],
            maxLength: 120,
            textCapitalization: TextCapitalization.sentences,
            decoration: InputDecoration(
              labelText: 'Statement ${index + 1}',
              hintText: 'A fun fact about you',
              counterText: '',
              filled: true,
              fillColor: AppColors.background,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: ChoiceChip(
              label: const Text('This one is the lie'),
              selected: lieIndex == index,
              onSelected: (_) => onLieChanged(index),
              selectedColor: AppColors.peachSoft,
              labelStyle: AppTypography.caption.copyWith(
                color: lieIndex == index
                    ? AppColors.coral
                    : AppColors.textSecondary,
              ),
            ),
          ),
        ],
        const SizedBox(height: 5),
        Row(
          children: [
            TextButton(
              onPressed: busy ? null : onCancel,
              child: const Text('Cancel'),
            ),
            const Spacer(),
            FilledButton(
              onPressed: busy ? null : onStart,
              child: Text(busy ? 'Creating…' : 'Create game'),
            ),
          ],
        ),
      ],
    ),
  );
}
