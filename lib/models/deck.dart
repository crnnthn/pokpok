import 'dart:math';

import 'playing_card.dart';
import 'suit.dart';

// Paquet de cartes
class Deck {
  // Paquet de 52 cartes
  Deck({Random? random})
    :_random = random ?? Random(),
    _cards = _buildFullDeck() {
      shuffle();
    }

  // Crée un paquet sans mélanger
  Deck.fromCards(List<PlayingCard> cards)
    : _random = Random(),
    _cards = cards.reversed.toList(); // stocjer à l'envers car `draw()` retire la dernière carte

  final Random _random;
  final List<PlayingCard> _cards;

  // Nombre de cartes dans le paquet
  int get remaining => _cards.length;

  // Génère les 52 cartes
  static List<PlayingCard> _buildFullDeck() => [
    for (final suit in Suit.values)
      for (var rank = 2; rank <= 14; rank++) PlayingCard(rank, suit),
  ];

  // Mélange de paquet
  void shuffle() {
    for (var i = _cards.length - 1; i > 0;i--) {
      final j = _random.nextInt(i+1);
      final tmp = _cards[i];
      _cards[i] = _cards[j];
      _cards[j] = tmp;
    }
  }

  // Tire la carte du dessus
  PlayingCard draw() {
    if (_cards.isEmpty) {
      throw StateError('Le paquet est vide');
    }
    return _cards.removeLast();
  }
}