import 'package:client/models/game_config.dart';
import 'package:client/models/playing_card.dart';
import 'package:client/models/suit.dart';
import 'package:client/services/fake_data_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('les cartes ont un libellé lisible', () {
    expect(const PlayingCard(14, Suit.spades).toString(), 'A♠');
    expect(const PlayingCard(10, Suit.hearts).toString(), '10♥');
    expect(const PlayingCard(12, Suit.clubs).rankLabel, 'Q');
  });

  test('deux cartes identiques sont égales', () {
    expect(const PlayingCard(7, Suit.diamonds),
        const PlayingCard(7, Suit.diamonds));
  });

  test('les blinds suivent le tapis de départ', () {
    expect(GameConfig.blindsFor(1000), (10, 20));
    expect(() => GameConfig.blindsFor(123), throwsArgumentError);
  });

  test('les données fictives donnent 6 joueurs avec le même tapis', () {
    final players = FakeDataService.players();
    expect(players.length, 6);
    expect(players.first.isHuman, isTrue);
    expect(players.every((p) => p.stack == 1000), isTrue);
  });

  test('le record de tapis est mémorisé', () {
    final p = FakeDataService.players().first;
    p.setStack(1500);
    p.setStack(300);
    expect(p.maxStack, 1500);
  });
}