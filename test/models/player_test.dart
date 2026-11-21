import 'package:client/models/hand_value.dart';
import 'package:client/models/player.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('bestHand ne garde que la meilleure main vue', () {
    final p = Player(id: 0, name: 'Test', emoji: '🦊', stack: 1000);
    expect(p.bestHand, isNull);

    p.updateBestHand(const HandValue(HandCategory.pair, [14, 13, 9, 7]));
    p.updateBestHand(const HandValue(HandCategory.flush, [14, 13, 9, 7, 4]));
    // Une main plus faible ne remplace pas la meilleure.
    p.updateBestHand(const HandValue(HandCategory.pair, [14, 13, 9, 7]));

    expect(p.bestHand!.category, HandCategory.flush);
  });
}