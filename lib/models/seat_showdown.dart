// Révélation d'une main
enum SeatResult {
  leading('Meilleure main'),
  tied('Égalité'),
  beaten('Battue'),
  winner('Gagne');

  const SeatResult(this.label);

  final String label;
}

// L'affichage lorsqu'un joueur montre ses cartes
class SeatShowdown {
  const SeatShowdown({this.handLabel, this. result, this.winnings = 0});

  // Nom de la main
  final String? handLabel;

  // Absent quand un joueur resté seul montre sa main
  final SeatResult? result;

  // Jetons gagnés
  final int winnings;

  // Texte affiché sous le nom de la main
  String? get resultText => result == SeatResult.winner ? 'Gagne $winnings' : result?.label;

  // Vrai si le nom de la main doit être affiché
  bool get isHighlighted => result == SeatResult.leading || result == SeatResult.winner;
}