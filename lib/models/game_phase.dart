// Phases d'une main de poker
enum GamePhase {
  preflop('Pré-flop', 0),
  flop('Flop', 3),
  turn('Turn', 4),
  river('River', 5),
  showdown('Showdown', 5);

  const GamePhase(this.label, this.communityCards);

  //Nom affiché à l'écran
  final String label;

  // Nombre de cartes visibles
  final int communityCards;
}