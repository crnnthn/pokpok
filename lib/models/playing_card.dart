import 'suit.dart';

// Carte à jouer
// Le rang est un entier : 2..10, puis Valet = 11, Dame = 12, Roi = 13 et As = 14 (l'As vaut aussi 1

class PlayingCard {
  const PlayingCard(this.rank, this.suit) 
    : assert(rank >= 2 && rank <=14, 'Le rang doit être compris entre 2 et 14');

  // Valeur de la carte, de 2 à 14.
  final int rank;

  //Couleur de la carte
  final Suit suit;

  // Libellé des rang
  String get rankLabel => switch (rank) {
    14 => 'A',
    13 => 'K',
    12 => 'Q',
    11 => 'J',
    _ => "$rank",
  };

  // Cas : cartes identiques
  @override
  bool operator ==(Object other)  => other is PlayingCard && other.rank == rank && other.suit == suit;

  @override
  int get hashCode => Object.hash(rank, suit);

  @override
  String toString() => '$rankLabel${suit.symbole}';
}