import 'hand_value.dart';
import 'playing_card.dart';
import 'suit.dart';

// Calcule la meilleure main de poker
class HandEvaluator {
  HandEvaluator._();

  // Évalue la meilleure main (5 ou plus cartes)
  static HandValue evaluate(List<PlayingCard> cards) {
    assert(
      cards.length >= 5 && cards.length <= 7,
      'Il faut entre 5 et 7 cartes',
    );

    // Rangs triés, fort -> faible
    final ranks = cards.map((c) => c.rank).toList()
      ..sort((a, b) => b.compareTo(a));

    // Groupes de rangs identiques, triés par taille puis par rang.
    final counts = <int, int>{};
    for (final r in ranks) {
      counts[r] = (counts[r] ?? 0) + 1;
    }
    final groups = counts.entries.toList()
      ..sort((a, b) {
        final byCount = b.value.compareTo(a.value);
        return byCount != 0 ? byCount : b.key.compareTo(a.key);
      });

    // Rangs de la couleur (si 5 ou plus)
    final bySuit = <Suit, List<int>>{};
    for (final c in cards) {
      (bySuit[c.suit] ??= []).add(c.rank);
    }
    List<int>? flushRanks;
    for (final suited in bySuit.values) {
      if (suited.length >= 5) {
        flushRanks = [...suited]..sort((a, b) => b.compareTo(a));
      }
    }

    // Cartes restantes les plus fortes
    List<int> kickers(List<int> exclude, int n) =>
        ranks.where((r) => !exclude.contains(r)).take(n).toList();

    // 1. Quinte flush
    if (flushRanks != null) {
      final sf = _straightHigh(flushRanks);
      if (sf != 0) return HandValue(HandCategory.straightFlush, [sf]);
    }

    // 2. Carré
    if (groups[0].value == 4) {
      final quad = groups[0].key;
      return HandValue(HandCategory.fourOfAKind, [
        quad,
        ...kickers([quad], 1),
      ]);
    }

    // 3. Full
    if (groups[0].value == 3 && groups.length > 1 && groups[1].value >= 2) {
      return HandValue(HandCategory.fullHouse, [groups[0].key, groups[1].key]);
    }

    // 4. Couleur
    if (flushRanks != null) {
      return HandValue(HandCategory.flush, flushRanks.take(5).toList());
    }

    // 5. Quinte
    final straight = _straightHigh(ranks);
    if (straight != 0) return HandValue(HandCategory.straight, [straight]);

    // 6. Brelan
    if (groups[0].value == 3) {
      final trips = groups[0].key;
      return HandValue(HandCategory.threeOfAKind, [
        trips,
        ...kickers([trips], 2),
      ]);
    }

    // 7. Double paire
    if (groups[0].value == 2 && groups.length > 1 && groups[1].value == 2) {
      final high = groups[0].key;
      final low = groups[1].key;
      return HandValue(HandCategory.twoPair, [
        high,
        low,
        ...kickers([high, low], 1),
      ]);
    }

    // 8. Paire
    if (groups[0].value == 2) {
      final pair = groups[0].key;
      return HandValue(HandCategory.pair, [
        pair,
        ...kickers([pair], 3),
      ]);
    }

    // 9. Carte haute
    return HandValue(HandCategory.highCard, ranks.take(5).toList());
  }

  // Déterminer la quinte la plus haute
  static int _straightHigh(List<int> ranks) {
    // Rangs uniques, fort -> faible
    final unique = ranks.toSet().toList()..sort((a, b) => b.compareTo(a));
    if (unique.first == 14) unique.add(1);

    var run = 1;
    for (var i = 1; i < unique.length; i++) {
      if (unique[i] == unique[i -1] - 1) {
        run++;
        if (run >=5) return unique[i] + 4;
      } else {
        run = 1;
      }
    }
    return 0;
  }
}
