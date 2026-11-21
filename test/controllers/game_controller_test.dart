import 'dart:math';

import 'package:client/controllers/game_controller.dart';
import 'package:client/models/deck.dart';
import 'package:client/models/game_phase.dart';
import 'package:client/services/fake_data_service.dart';
import 'package:flutter_test/flutter_test.dart';

/// Crée un controller de test avec un paquet reproductible.
GameController makeController({int initialDealer = 0}) => GameController(
      config: FakeDataService.config,
      players: FakeDataService.players(),
      initialDealer: initialDealer,
      deckBuilder: () => Deck(random: Random(1)),
    );

void main() {
  test('à 6 joueurs : dealer, blinds et premier à parler', () {
    final c = makeController(); // dealer de départ = siège 0
    c.startHand();

    expect(c.dealerIndex, 1); // le bouton avance d'un siège
    expect(c.smallBlindIndex, 2);
    expect(c.bigBlindIndex, 3);
    expect(c.currentPlayerIndex, 4); // à gauche de la grosse blind
    expect(c.phase, GamePhase.preflop);
    expect(c.handNumber, 1);
  });

  test('les blinds sont prélevées et le pot est correct', () {
    final c = makeController();
    c.startHand();

    expect(c.players[2].bet, 10);
    expect(c.players[2].stack, 990);
    expect(c.players[3].bet, 20);
    expect(c.players[3].stack, 980);
    expect(c.pot, 30);
    expect(c.currentBet, 20);
    expect(c.minRaise, 20);
  });

  test('chaque joueur reçoit 2 cartes, le board est vide', () {
    final c = makeController();
    c.startHand();

    expect(c.players.every((p) => p.holeCards.length == 2), isTrue);
    expect(c.board, isEmpty);
  });

  test('heads-up : le dealer est petite blind et parle en premier', () {
    final c = makeController();
    for (final p in c.players.skip(2)) {
      p.eliminated = true; // il ne reste que les sièges 0 et 1
    }
    c.startHand();

    expect(c.dealerIndex, 1);
    expect(c.smallBlindIndex, 1);
    expect(c.bigBlindIndex, 0);
    expect(c.currentPlayerIndex, 1);
    // Les joueurs éliminés ne reçoivent ni carte ni blind.
    expect(c.players[2].holeCards, isEmpty);
    expect(c.players[2].bet, 0);
  });

  test('une blind plus grosse que le tapis met le joueur à tapis', () {
    final c = makeController();
    c.players[2].stack = 5; // la petite blind (10) dépasse son tapis
    c.startHand();

    expect(c.players[2].bet, 5);
    expect(c.players[2].stack, 0);
    expect(c.pot, 25); // 5 + 20
    expect(c.currentBet, 20);
  });

  test('la main suivante déplace le bouton et remet les mises à zéro', () {
    final c = makeController();
    c.startHand();
    c.startHand();

    expect(c.dealerIndex, 2);
    expect(c.handNumber, 2);
    // Les mises de la 1re main ont été remises à zéro avant les nouvelles blinds.
    expect(c.pot, 30);
  });
}