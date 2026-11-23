import 'dart:math';

import 'package:client/controllers/game_controller.dart';
import 'package:client/models/deck.dart';
import 'package:client/models/game_config.dart';
import 'package:client/models/game_phase.dart';
import 'package:client/models/hand_value.dart';
import 'package:client/models/playing_card.dart';
import 'package:client/models/player_action.dart';
import 'package:client/models/suit.dart';
import 'package:client/services/fake_data_service.dart';
import 'package:flutter_test/flutter_test.dart';

/// Lit des cartes écrites en texte : "Ac Ks 10d" (rang + initiale s/h/d/c).
List<PlayingCard> cards(String text) {
  const ranks = {'A': 14, 'K': 13, 'Q': 12, 'J': 11};
  const suits = {
    's': Suit.spades,
    'h': Suit.hearts,
    'd': Suit.diamonds,
    'c': Suit.clubs,
  };
  return text.split(' ').map((t) {
    final rank = t.substring(0, t.length - 1);
    return PlayingCard(ranks[rank] ?? int.parse(rank), suits[t[t.length - 1]]!);
  }).toList();
}

/// Partie à 3 joueurs (sièges 0, 1, 2) avec un paquet imposé.
/// Dealer = 1, petite blind = 2, grosse blind = 0, premier à parler = 1.
/// Ordre de tirage : 2 cartes à chaque joueur en partant du siège 2
/// (2, 0, 1, 2, 0, 1), puis flop (3), turn (1), river (1).
GameController scripted(String drawOrder, {GameConfig? config}) {
  final c = GameController(
    config: config ?? FakeDataService.config,
    players: FakeDataService.players(),
    initialDealer: 0,
    deckBuilder: () => Deck.fromCards(cards(drawOrder)),
  );
  for (final p in c.players.skip(3)) {
    p.eliminated = true;
  }
  return c;
}

/// Tout le monde check ou suit jusqu'au showdown.
void playToShowdown(GameController c) {
  while (c.phase != GamePhase.showdown) {
    final p = c.currentPlayer!;
    c.act(c.toCall(p) == 0
        ? const PlayerAction.check()
        : const PlayerAction.callBet());
  }
}

// Siège 2 : A♣ 3♣ (carte haute) · siège 0 : K♠ K♥ (brelan de rois)
// siège 1 : 9♠ 9♦ (brelan de 9) · board : 2♦ 7♣ 9♥ J♠ K♦
const trips = 'Ac Ks 9s 3c Kh 9d 2d 7c 9h Js Kd';

void main() {
  test('showdown : mains révélées une par une, le meilleur brelan gagne', () {
    final c = scripted(trips)..startHand();
    playToShowdown(c);

    expect(c.handFinished, isFalse);
    expect(c.pot, 60);

    // Ordre : à gauche du dealer → sièges 2, 0, 1.
    c.revealNextHand();
    expect(c.reveals.last.player.id, 2);
    expect(c.reveals.last.value!.category, HandCategory.highCard);
    expect(c.reveals.last.isLeading, isTrue); // première main montrée

    c.revealNextHand();
    expect(c.reveals.last.player.id, 0);
    expect(c.reveals.last.value!.category, HandCategory.threeOfAKind);
    expect(c.reveals.last.isLeading, isTrue); // bat la carte haute

    c.revealNextHand();
    expect(c.reveals.last.player.id, 1);
    expect(c.reveals.last.isLeading, isFalse); // brelan de 9 < brelan de rois

    expect(c.handFinished, isTrue);
    expect(c.winners.map((p) => p.id), [0]);
    expect(c.winnings, {0: 60});
    expect(c.pot, 0);
    expect(c.players[0].stack, 1040); // 1000 - 20 + 60
    expect(c.players[0].handsWon, 1);
    expect(c.players[1].stack, 980);
    expect(c.players[0].bestHand!.category, HandCategory.threeOfAKind);
    expect(() => c.revealNextHand(), throwsStateError);
  });

  test('égalité : le pot est partagé, le reste va au premier gagnant', () {
    // Blinds 5/10 ; le board est une quinte flush royale que tout le monde joue.
    final c = scripted(
      '2d 4h 6c 3c 5d 7h As Ks Qs Js 10s',
      config: GameConfig.fromStack(
        name: 'Test',
        maxPlayers: 6,
        startingStack: 500,
      ),
    )..startHand();

    c.act(const PlayerAction.callBet()); // siège 1 suit 10
    c.act(const PlayerAction.fold()); // siège 2 (SB) se couche : perd 5
    playToShowdown(c); // le siège 0 (BB) et le siège 1 vont au showdown
    expect(c.pot, 25);

    c.revealNextHand(); // siège 0
    c.revealNextHand(); // siège 1

    expect(c.winners.map((p) => p.id), [0, 1]);
    expect(c.winnings, {0: 13, 1: 12}); // 25 ÷ 2 = 12, le reste (1) au siège 0
    expect(c.players[0].stack, 1003);
    expect(c.players[1].stack, 1002);
  });

  test('joueur seul : il gagne le pot et peut montrer sa main', () {
    final c = GameController(
      config: FakeDataService.config,
      players: FakeDataService.players(),
      initialDealer: 0,
      deckBuilder: () => Deck(random: Random(1)),
    )..startHand();

    for (var i = 0; i < 5; i++) {
      c.act(const PlayerAction.fold()); // sièges 4, 5, 0, 1, 2
    }

    expect(c.handFinished, isTrue);
    expect(c.winners.map((p) => p.id), [3]); // la grosse blind
    expect(c.winnings, {3: 30});
    expect(c.players[3].stack, 1010); // 1000 - 20 + 30
    expect(c.pot, 0);

    // Avant le flop, il montre ses cartes mais il n'y a pas de main évaluable.
    c.revealWinnerHand();
    expect(c.reveals.single.player.id, 3);
    expect(c.reveals.single.value, isNull);
  });

  test('un joueur qui perd tous ses jetons est éliminé', () {
    final c = scripted(trips);
    c.players[2].stack = 20; // il sera à tapis après la petite blind + son appel
    c.startHand();
    playToShowdown(c);

    expect(c.players[2].stack, 0);
    c.revealNextHand();
    c.revealNextHand();
    c.revealNextHand();

    expect(c.players[2].eliminated, isTrue);
    expect(c.players[2].lastAction, 'Éliminé');
    expect(c.players[0].eliminated, isFalse);
    expect(c.activePlayerCount, 2);
  });
}