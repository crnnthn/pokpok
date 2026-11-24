import 'dart:math';

import 'package:client/controllers/bot_controller.dart';
import 'package:client/controllers/game_controller.dart';
import 'package:client/controllers/game_runner.dart';
import 'package:client/models/deck.dart';
import 'package:client/models/game_config.dart';
import 'package:client/models/game_phase.dart';
import 'package:client/models/player.dart';
import 'package:client/models/player_action.dart';
import 'package:flutter_test/flutter_test.dart';

/// Partie à 6 joueurs ; le siège 0 est humain si [human] est vrai.
/// Paquets reproductibles : un même générateur alimente toutes les mains.
GameController makeGame({
  required bool human,
  required int stack,
  required int smallBlind,
  required int bigBlind,
  int seed = 1,
}) {
  final rng = Random(seed);
  return GameController(
    config: GameConfig(
      name: 'Test',
      maxPlayers: 6,
      startingStack: stack,
      smallBlind: smallBlind,
      bigBlind: bigBlind,
    ),
    players: [
      for (var i = 0; i < 6; i++)
        Player(
          id: i,
          name: 'J$i',
          emoji: '🤖',
          stack: stack,
          isHuman: human && i == 0,
        ),
    ],
    initialDealer: 0,
    deckBuilder: () => Deck(random: rng),
  );
}

/// Runner sans aucun délai, avec un timer de tour très court.
GameRunner makeRunner(
  GameController game, {
  Duration turnTimeout = const Duration(milliseconds: 20),
}) => GameRunner(
  game: game,
  bot: BotController(random: Random(7)),
  botDelay: Duration.zero,
  revealDelay: Duration.zero,
  betweenHands: Duration.zero,
  turnTimeout: turnTimeout,
);

void main() {
  test('une partie entre bots va jusqu\'au dernier joueur', () async {
    // Gros blinds par rapport au tapis : la partie est courte.
    final game = makeGame(
      human: false,
      stack: 200,
      smallBlind: 50,
      bigBlind: 100,
    );
    await makeRunner(game).run(maxHands: 500);

    expect(game.isGameOver, isTrue);
    expect(game.gameWinner!.stack, 1200); // tous les jetons : 6 × 200
  });

  test(
    'un joueur humain inactif est exclu après 2 timeouts de suite',
    () async {
      final game = makeGame(
        human: true,
        stack: 1000,
        smallBlind: 10,
        bigBlind: 20,
      );
      await makeRunner(game).run(maxHands: 30);

      final human = game.players[0];
      expect(human.eliminated, isTrue);
      expect(human.consecutiveTimeouts, 2);
      expect(human.totalTimeouts, 2);
    },
  );

  test('un joueur humain qui joue à temps n\'a aucun timeout', () async {
    final game = makeGame(
      human: true,
      stack: 1000,
      smallBlind: 10,
      bigBlind: 20,
    );
    final runner = makeRunner(game, turnTimeout: const Duration(seconds: 5));

    var done = false;
    final running = runner.run(maxHands: 1).then((_) => done = true);

    // Le test joue à la place de l'humain : il checke ou suit à son tour.
    for (var i = 0; i < 20000 && !done; i++) {
      final p = game.currentPlayer;
      if (p != null && p.isHuman && game.phase != GamePhase.showdown) {
        game.act(
          game.toCall(p) == 0
              ? const PlayerAction.check()
              : const PlayerAction.callBet(),
        );
      }
      await Future<void>.delayed(Duration.zero);
    }
    await running;

    expect(game.handNumber, 1);
    expect(game.players[0].totalTimeouts, 0);
    expect(game.players[0].lastAction, isNot('Exclu'));
  });
}
