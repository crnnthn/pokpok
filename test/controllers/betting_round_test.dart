import 'dart:math';

import 'package:client/controllers/game_controller.dart';
import 'package:client/models/deck.dart';
import 'package:client/models/game_phase.dart';
import 'package:client/models/player_action.dart';
import 'package:client/services/fake_data_service.dart';
import 'package:flutter_test/flutter_test.dart';

/// Controller de test : dealer de départ au siège 0, donc après startHand()
/// dealer = 1, SB = 2, BB = 3 et premier à parler = 4.
GameController makeController() => GameController(
      config: FakeDataService.config,
      players: FakeDataService.players(),
      initialDealer: 0,
      deckBuilder: () => Deck(random: Random(1)),
    );

/// Le joueur courant suit [times] fois de suite.
void callTimes(GameController c, int times) {
  for (var i = 0; i < times; i++) {
    c.act(const PlayerAction.callBet());
  }
}

void main() {
  test('tour pré-flop : ordre de parole puis passage au flop', () {
    final c = makeController()..startHand();

    callTimes(c, 4); // sièges 4, 5, 0, 1
    expect(c.currentPlayerIndex, 2); // la petite blind complète
    c.act(const PlayerAction.callBet());
    expect(c.currentPlayerIndex, 3); // la grosse blind a l'option
    c.act(const PlayerAction.check());

    expect(c.phase, GamePhase.flop);
    expect(c.board.length, 3);
    expect(c.pot, 120); // 6 joueurs × 20
    expect(c.currentBet, 0);
    expect(c.players.every((p) => p.bet == 0), isTrue);
    expect(c.currentPlayerIndex, 2); // premier à gauche du dealer
  });

  test('une relance oblige tout le monde à reparler', () {
    final c = makeController()..startHand();

    c.act(const PlayerAction.raiseTo(60)); // siège 4
    expect(c.currentBet, 60);
    expect(c.minRaise, 40); // 60 - 20
    expect(c.currentPlayerIndex, 5);
    expect(c.minRaiseTo, 100);

    callTimes(c, 5); // sièges 5, 0, 1, 2, 3
    expect(c.phase, GamePhase.flop);
    expect(c.pot, 360); // 6 joueurs × 60
  });

  test('si tout le monde se couche, il reste un seul joueur en lice', () {
    final c = makeController()..startHand();

    for (var i = 0; i < 5; i++) {
      c.act(const PlayerAction.fold()); // sièges 4, 5, 0, 1, 2
    }

    expect(c.phase, GamePhase.showdown);
    expect(c.currentPlayerIndex, -1);
    expect(c.players.where((p) => p.inHand).length, 1);
    expect(c.players[3].inHand, isTrue); // la grosse blind
  });

  test('les actions illégales sont refusées sans rien modifier', () {
    final c = makeController()..startHand();

    expect(() => c.act(const PlayerAction.check()), throwsArgumentError);
    expect(() => c.act(const PlayerAction.raiseTo(30)), throwsArgumentError);
    expect(() => c.act(const PlayerAction.raiseTo(5000)), throwsArgumentError);
    expect(c.currentPlayerIndex, 4);
    expect(c.pot, 30);
  });

  test('on arrive au showdown avec 5 cartes communes', () {
    final c = makeController()..startHand();

    while (c.phase != GamePhase.showdown) {
      final p = c.currentPlayer!;
      c.act(c.toCall(p) == 0
          ? const PlayerAction.check()
          : const PlayerAction.callBet());
    }

    expect(c.board.length, 5);
    expect(c.pot, 120);
  });

  test('un joueur à tapis ne parle plus aux tours suivants', () {
    final c = makeController();
    c.players[4].stack = 15; // trop court pour suivre la grosse blind
    c.startHand();

    c.act(const PlayerAction.callBet()); // siège 4 : tapis de 15
    expect(c.players[4].lastAction, 'Tapis 15');
    expect(c.players[4].stack, 0);

    callTimes(c, 4); // sièges 5, 0, 1, 2
    c.act(const PlayerAction.check()); // siège 3

    expect(c.phase, GamePhase.flop);
    expect(c.pot, 115); // 15 + 5 × 20
    expect(c.players[4].canAct, isFalse);
    expect(c.currentPlayerIndex, 2);
  });

  test('heads-up : la SB parle la première avant le flop, la BB après', () {
    final c = makeController();
    for (final p in c.players.skip(2)) {
      p.eliminated = true;
    }
    c.startHand(); // dealer = SB = siège 1, BB = siège 0

    c.act(const PlayerAction.callBet()); // la SB complète
    c.act(const PlayerAction.check()); // la BB a l'option

    expect(c.phase, GamePhase.flop);
    expect(c.currentPlayerIndex, 0); // la BB parle en premier après le flop
  });
}