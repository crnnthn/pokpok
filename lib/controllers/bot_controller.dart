import 'dart:math';

import '../models/hand_evaluator.dart';
import '../models/hand_value.dart';
import '../models/playing_card.dart';
import '../models/player.dart';
import '../models/player_action.dart';
import 'game_controller.dart';

// Décide de l'action d'un joueur contrôlé par ordinateur
class BotController {
  BotController({Random? random}) : _random = random ?? Random();

  // Nombre max de relances par tour de  mise
  static const int maxRaisesPerRound = 3;

  final Random _random;

  // Choisi l'action du joueur
  PlayerAction decide(GameController game) {
    final player = game.currentPlayer;
    if (player == null) {
      throw StateError('Aucun joueur ne peut agir actuellement');
    }

    final toCall = game.toCall(player);
    final bigBlind = game.config.bigBlind;
    final strength = _strength(player,game.board);
    final roll = _random.nextDouble();
    final canRaises = game.raisesInRound < maxRaisesPerRound && player.stack >toCall;

    // Rien à payer
    if (toCall == 0) {
      if (canRaises && roll < strength * 0.55) {
        final target = max(
          bigBlind.toDouble(),
          game.pot * (0.4 + _random.nextDouble() * 0.4),
        );
        return PlayerAction.raiseTo(_legalRaise(game, player, target));
      }
      return const PlayerAction.check();
    }
    
    // Mise à payer : fold rare si peu cher
    final isCheap = toCall <= bigBlind * 2;
    final foldChance = isCheap ? 0.04 : max(0.0, 0.65 - strength) + (toCall > player.stack * 0.5 ? 0.25 : 0.0);
    if (roll < foldChance) return const PlayerAction.fold();

    // Mains fortes : relancent possible
    if (canRaises && roll > 1 - strength * 0.22) {
      final target = game.currentBet + max(bigBlind.toDouble(), game.pot * 0.6);
      return PlayerAction.raiseTo(_legalRaise(game, player, target));
    }
    return const PlayerAction.callBet();
  }

  // Force estimée de la main, de 0 à 1
  double _strength(Player player, List<PlayingCard> board) {
    final cards = player.holeCards;

    // Après flop
    if (board.isNotEmpty) {
      final category = HandEvaluator.evaluate([...cards, ...board]).category;
      final highCard = max(cards[0].rank, cards[1].rank);

      return switch(category) {
        HandCategory.highCard => 0.25 + highCard / 60,
        HandCategory.pair => 0.6,
        HandCategory.twoPair => 0.85,
        _ => 0.95, // brelan ou mieux
      };
    }

    // Avant le flop
    final a = cards[0];
    final b = cards[1];
    if (a.rank == b.rank) return 0.72 + a.rank / 60;

    return min(
      0.85,
      (a.rank + b.rank) / 28 * 0.6 + (a.suit == b.suit ? 0.06 : 0.0) + ((a.rank - b.rank).abs() < 3 ? 0.05 : 0.0),
    );
  }

  // Transforme une mise en relance
  int _legalRaise(GameController game, Player player, num target) {
    final smallBlind = game.config.smallBlind;
    final rounded = (target / smallBlind).round() * smallBlind;
    final maxTo = player.bet + player.stack;
    return min(maxTo, max(game.minRaiseTo, rounded));
  }
}