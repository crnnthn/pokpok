import 'playing_card.dart';
import 'hand_value.dart';

// Joueur
class Player {
  Player({
    required this.id,
    required this.name,
    required this.emoji,
    required this.stack,
    this.isHuman = false,
  }) : maxStack = stack;

  // Position du joueur à la table
  final int id;

  // Pseudo du joueur
  final String name;

  // Avatar du joueur
  final String emoji;

  // Définir si bot ou non
  final bool isHuman;

  // ---- État de la main en cours ----

  // Jetons restants
  int stack;

  // Jetons misés pendant un tour
  int bet = 0;

  // Abandon
  bool folded = false;

  // Dernière action
  String lastAction = '';

  // Main du joueur
  List<PlayingCard> holeCards = [];

  // ---- État de la partie ----

  // Éliminé
  bool eliminated = false;

  // Timers écoulés d'affilée : à 2, le joueur est exclu
  int consecutiveTimeouts = 0;

  // Timers écoulés au total : à 3, exclusion.
  int totalTimeouts = 0;

  // ---- Statistiques de fin de partie ----

  // Plus gros tapis
  int maxStack;

  // Nombre de mains gagnées
  int handsWon = 0;

  // Peut agit (non couché, avec jetons)
  bool get canAct => !eliminated && !folded && stack > 0;

  // Peut ganger
  bool get inHand => !eliminated && !folded;

  // Meilleure main atteinte
  HandValue ? bestHand;

  // Retenir si elle est meilleure que celle connue
  void updateBestHand(HandValue value) {
    final current = bestHand;
    if (current == null || value.compareTo(current) > 0) {
      bestHand = value;
    }
  }

  // Modifier un tapis
  void setStack(int value) {
    stack = value;
    if (stack > maxStack) maxStack = stack;
  }

  // Reset à zéro des éléments d'un joueur
  void resetForNewHand(){
    bet = 0;
    folded = eliminated;

    lastAction = eliminated ? 'Éliminé' : '';
    holeCards = [];
  }

  @override
  String toString() => '$name($stack)';
}
