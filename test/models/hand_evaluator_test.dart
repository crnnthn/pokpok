import 'package:client/models/hand_evaluator.dart';
import 'package:client/models/hand_value.dart';
import 'package:client/models/playing_card.dart';
import 'package:client/models/suit.dart';
import 'package:flutter_test/flutter_test.dart';

/// Lit une main écrite en texte : "As Kh 10d" (rang + initiale s/h/d/c).
List<PlayingCard> hand(String text) {
  const ranks = {'A': 14, 'K': 13, 'Q': 12, 'J': 11};
  const suits = {
    's': Suit.spades,
    'h': Suit.hearts,
    'd': Suit.diamonds,
    'c': Suit.clubs,
  };
  return text.split(' ').map((token) {
    final rankText = token.substring(0, token.length - 1);
    final suit = suits[token[token.length - 1]]!;
    return PlayingCard(ranks[rankText] ?? int.parse(rankText), suit);
  }).toList();
}

HandValue eval(String text) => HandEvaluator.evaluate(hand(text));

void main() {
  test('quinte flush royale', () {
    final v = eval('As Ks Qs Js 10s 2h 3d');
    expect(v.category, HandCategory.straightFlush);
    expect(v.label, 'Quinte flush royale');
  });

  test('la roue A-2-3-4-5 est une quinte à 5, battue par une quinte à 6', () {
    final wheel = eval('As 2d 3h 4c 5s 9d Kh');
    final six = eval('2s 3d 4h 5c 6s 9d Kh');
    expect(wheel.category, HandCategory.straight);
    expect(wheel.tiebreakers, [5]);
    expect(wheel.compareTo(six), lessThan(0));
  });

  test('un full avec deux brelans garde le plus fort brelan', () {
    final v = eval('3s 3d 3h Kc Ks Kd 7h');
    expect(v.category, HandCategory.fullHouse);
    expect(v.tiebreakers, [13, 3]);
  });

  test('la couleur bat la quinte', () {
    final flush = eval('As 9s 7s 4s 2s Kh Qd');
    final straight = eval('5h 6d 7c 8s 9h Kd 2c');
    expect(flush.compareTo(straight), greaterThan(0));
  });

  test('la quinte flush bat le carré', () {
    final sf = eval('5h 6h 7h 8h 9h Kd Kc');
    final quads = eval('9s 9d 9c 9h 2s 3d 4c');
    expect(sf.compareTo(quads), greaterThan(0));
  });

  test('avec trois paires, on garde les deux plus fortes + un kicker', () {
    final v = eval('As Ad Kh Kc 9s 9d 2c');
    expect(v.category, HandCategory.twoPair);
    expect(v.tiebreakers, [14, 13, 9]);
  });

  test('deux paires identiques sont départagées par les kickers', () {
    final a = eval('As Ad Kh 9c 7s 4d 2c');
    final b = eval('Ac Ah Kd 9h 6d 3s 2d');
    expect(a.compareTo(b), greaterThan(0));
  });

  test('le board joue : égalité parfaite', () {
    final a = eval('As Kd Qh Jc 10s 2d 3c');
    final b = eval('As Kd Qh Jc 10s 4h 5d');
    expect(a.compareTo(b), 0);
  });

  test('carte haute : les 5 plus fortes cartes', () {
    final v = eval('2s 4d 7h 9c Js Kd 3h');
    expect(v.category, HandCategory.highCard);
    expect(v.tiebreakers, [13, 11, 9, 7, 4]);
  });

  test('couleur à 6 cartes : on garde les 5 plus fortes', () {
    final v = eval('As Ks 9s 7s 4s 2s 3d');
    expect(v.category, HandCategory.flush);
    expect(v.tiebreakers, [14, 13, 9, 7, 4]);
  });

  test('carré avec kicker et brelan avec kickers', () {
    expect(eval('9s 9d 9c 9h As 2d 3c').tiebreakers, [9, 14]);
    expect(eval('Qs Qd Qc 9h 7s 4d 2c').tiebreakers, [12, 9, 7]);
  });
}