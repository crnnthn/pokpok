import 'dart:async';

import '../models/game_phase.dart';
import 'bot_controller.dart';
import 'game_controller.dart';

// Fait avancer la partie dans le temps
class GameRunner {
  GameRunner({
    required this.game,
    BotController? bot,
    this.botDelay = const Duration(milliseconds: 900),
    this.revealDelay = const Duration(milliseconds: 800),
    this.betweenHands = const Duration(seconds: 3),
    Duration? turnTimeout,
  }) : bot = bot ?? BotController(),
       turnTimeout = turnTimeout ?? Duration(seconds: game.config.turnSeconds);

  final GameController game;
  final BotController bot;

  // Temps de réflexion d'un bot
  final Duration botDelay;

  // Pause entre deux révéléation de mains
  final Duration revealDelay;

  // Pause à la fin d'une main
  final Duration betweenHands;

  // Rempas accordé au joueur pour agir (30 s)
  final Duration turnTimeout;

  bool _stopped = false;
  Completer<void>? _humanWait;

  // Joue la partie jusqu'à la fin
  Future<void> run({int? maxHands}) async {
    var played = 0;
    while (!_stopped &&
        !game.isGameOver &&
        (maxHands == null || played < maxHands)) {
      game.startHand();
      played++;

      await _playBettingRounds();
      if (_stopped) return;

      await _playShowdown();
      if (_stopped) return;

      if (!game.isGameOver) await _pause(betweenHands);
    }
  }

  // Arrête la boucle
  void stop() {
    _stopped = true;
    final wait = _humanWait;
    if (wait != null && !wait.isCompleted) wait.complete();
  }

  // Joue tous les touts de mise de la main
  Future<void> _playBettingRounds() async {
    while (!_stopped && game.phase != GamePhase.showdown) {
      final player = game.currentPlayer;
      if (player == null) {
        throw StateError('Aucun joueur à faire jouer avant le showdown');
      }

      if (player.isHuman) {
        await _waitForHuman();
      } else {
        await _pause(botDelay);
        if (_stopped) return;
        game.act(bot.decide(game));
      }
    }
  }

  // Attends que le joueur humain agisse
  Future<void> _waitForHuman() async {
    final actionsBefore = game.actionCount;
    final wait = Completer<void>();
    _humanWait = wait;

    void onChange() {
        if (game.actionCount != actionsBefore && !wait.isCompleted){
            wait.complete();
        }
    }

    game.addListener(onChange);
    try {
        await wait.future.timeout(turnTimeout);
    } on TimeoutException {
        if (!_stopped) game.timeOutCurrentPlayer();
    } finally {
        game.removeListener(onChange);
        _humanWait = null;
    }
  }

  // Révèle les mains une par une
  Future<void> _playShowdown() async {
    while (!_stopped && !game.handFinished) {
        await _pause(revealDelay);
        if (_stopped) return;
        game.revealNextHand();
    }
  }

  Future<void> _pause(Duration duration) => Future<void>.delayed(duration);
}
