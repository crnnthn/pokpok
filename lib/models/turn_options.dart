import 'dart:math';

import 'player_action.dart';

// Ce que le joueur peut faire
class TurnOptions {
  const TurnOptions({
    required this.stack,
    required this.bet,
    required this.toCall,
    required this.currentBet,
    required this.minRaiseTo,
    required this.pot,
    required this.step,
  });

  // Jetons restants du joueur
  final int stack;

  // Mise dans le tour en cours
  final int bet;

  // Jetons pour suivre
  final int toCall;

  // Mise la plus haute du tour
  final int currentBet;

  // Plus petite mise pour relancer
  final int minRaiseTo;

  final int pot;

  // Egal à la petite blind
  final int step;

  bool get canCheck => toCall == 0;

  // Suivre coûterait tapis
  bool get isCallAllIn => toCall > 0 && toCall >= stack;

  // Nécessaire : plus de jetons que le montant à suivre
  bool get canRaise => stack > toCall;

  // Calcul du tapis
  int get maxRaiseTo => bet + stack;

  // Personne n'a encore misé à ce tour
  bool get isOpening => currentBet == 0;

  // Raccourcis du panneau de relance
  int get halfPotTo => clampRaise(currentBet + (pot + toCall) / 2);
  int get potTo => clampRaise(currentBet + pot + toCall);

  // Limiter le montant dans les limites
  int clampRaise(num target) {
    if (target >= maxRaiseTo) return maxRaiseTo;

    final rounded = (target / step).round() * step;
    return max(minRaiseTo, min(maxRaiseTo, rounded));
  }

  // Miser tout son tapis
  PlayerAction get allIn => maxRaiseTo > currentBet
      ? PlayerAction.raiseTo(maxRaiseTo)
      : const PlayerAction.callBet();
}
