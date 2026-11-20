import 'dart:math';

import 'package:client/models/deck.dart';
import 'package:client/models/playing_card.dart';
import 'package:client/models/suit.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('un paquet neuf contient 52 cartes toutes différentes', () {
    final deck = Deck();
    final drawn = <PlayingCard>{};
    while (deck.remaining > 0) {
      drawn.add(deck.draw());
    }
    expect(drawn.length, 52);
  });

  test('tirer une carte réduit le paquet', () {
    final deck = Deck();
    deck.draw();
    expect(deck.remaining, 51);
  });

  test('tirer dans un paquet vide lève une erreur', () {
    final deck = Deck.fromCards(const []);
    expect(deck.draw, throwsStateError);
  });

  test('même graine = même mélange', () {
    final a = Deck(random: Random(42));
    final b = Deck(random: Random(42));
    expect(
      List.generate(52, (_) => a.draw()),
      List.generate(52, (_) => b.draw()),
    );
  });

  test("fromCards conserve l'ordre donné (tutoriel)", () {
    final deck = Deck.fromCards(const [
      PlayingCard(14, Suit.spades),
      PlayingCard(13, Suit.hearts),
    ]);
    expect(deck.draw(), const PlayingCard(14, Suit.spades));
    expect(deck.draw(), const PlayingCard(13, Suit.hearts));
  });
}