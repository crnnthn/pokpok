import 'dart:math';

import 'package:client/controllers/bot_controller.dart';
import 'package:client/controllers/game_controller.dart';
import 'package:client/models/deck.dart';
import 'package:client/models/game_phase.dart';
import 'package:client/models/playing_card.dart';
import 'package:client/models/player_action.dart';
import 'package:client/models/suit.dart';
import 'package:client/services/fake_data_service.dart';
import 'package:flutter_test/flutter_test.dart';

/// Générateur « truqué » : renvoie toujours la même valeur entre 0 et 1.
class FixedRandom implements Random {
  FixedRandom(this.value);
  final double value;

  @override
  double nextDouble() => value;
  @override
  int nextInt(int max) => 0;
  @override
  bool nextBool() => false;
}

/// Lit des cartes écrites en texte : "As Kd" (rang + initiale s/h/d/c).
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

/// Après startHand() : dealer 1, SB 2, BB 3, premier à parler = siège 4.
GameController makeController() => GameController(
      config: FakeDataService.config,
      players: FakeDataService.players(),
      initialDealer: 0,
      deckBuilder: () => Deck(random: Random(1)),
    )..startHand();

void main() {
  test('pré-flop : une main faible se couche, passe ou relance selon le dé', () {
    final c = makeController();
    c.currentPlayer!.holeCards = cards('2c 7d'); // main faible, 20 à payer

    expect(BotController(random: FixedRandom(0.01)).decide(c).type,
        ActionType.fold);
    expect(BotController(random: FixedRandom(0.5)).decide(c).type,
        ActionType.call);

    final raise = BotController(random: FixedRandom(0.99)).decide(c);
    expect(raise.type, ActionType.raise);
    expect(raise.amount, 40); // 20 + max(20, 60 % du pot) = 40
  });

  test('rien à payer : le bot mise ou checke, il ne se couche jamais', () {
    final c = makeController();
    for (var i = 0; i < 4; i++) {
      c.act(const PlayerAction.callBet()); // sièges 4, 5, 0, 1
    }
    c.act(const PlayerAction.callBet()); // siège 2 (SB)
    c.act(const PlayerAction.check()); // siège 3 (BB) → flop
    c.currentPlayer!.holeCards = cards('As Ad');
    expect(c.pot, 120);

    final bet = BotController(random: FixedRandom(0.0)).decide(c);
    expect(bet.type, ActionType.raise);
    expect(bet.amount, 50); // 40 % du pot = 48, arrondi à la blind : 50

    expect(BotController(random: FixedRandom(0.99)).decide(c).type,
        ActionType.check);
  });

  test('après 3 relances, le bot ne relance plus même avec une main forte', () {
    final c = makeController();
    c.act(const PlayerAction.raiseTo(40)); // siège 4
    c.act(const PlayerAction.raiseTo(60)); // siège 5
    c.act(const PlayerAction.raiseTo(80)); // siège 0
    expect(c.raisesInRound, 3);

    c.currentPlayer!.holeCards = cards('As Ad');
    expect(BotController(random: FixedRandom(0.99)).decide(c).type,
        ActionType.call);
  });

  test('100 mains jouées par des bots : actions légales, jetons conservés', () {
    for (var seed = 0; seed < 100; seed++) {
      final c = GameController(
        config: FakeDataService.config,
        players: FakeDataService.players(),
        initialDealer: seed % 6,
        deckBuilder: () => Deck(random: Random(seed)),
      )..startHand();
      final bot = BotController(random: Random(seed));

      var guard = 0;
      while (c.phase != GamePhase.showdown) {
        c.act(bot.decide(c)); // une action illégale lèverait une erreur
        expect(++guard, lessThan(500), reason: 'boucle infinie (seed $seed)');
      }
      while (!c.handFinished) {
        c.revealNextHand();
      }

      final total = c.players.fold<int>(0, (sum, p) => sum + p.stack);
      expect(total, 6000, reason: 'jetons perdus (seed $seed)');
    }
  });
}