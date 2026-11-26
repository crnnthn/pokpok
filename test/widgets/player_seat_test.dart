import 'package:client/models/player.dart';
import 'package:client/models/playing_card.dart';
import 'package:client/models/seat_showdown.dart';
import 'package:client/models/suit.dart';
import 'package:client/widgets/player_seat.dart';
import 'package:client/widgets/playing_card_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Player makePlayer() =>
    Player(id: 1, name: 'Luna', emoji: '🐸', stack: 990)
      ..lastAction = 'Suit 20';

Future<void> pumpSeat(WidgetTester tester, Widget seat) => tester.pumpWidget(
  MaterialApp(
    home: Scaffold(body: Center(child: seat)),
  ),
);

// Opacité demandée au siège
double seatOpacity(WidgetTester tester) =>
    tester.widget<AnimatedOpacity>(find.byType(AnimatedOpacity)).opacity;

// Décoration de l'avatar
BoxDecoration avatarDecoration(WidgetTester tester) =>
    tester.widget<AnimatedContainer>(find.byType(AnimatedContainer)).decoration!
        as BoxDecoration;

void main() {
  testWidgets('le siège affiche le joueur sans ses cartes', (tester) async {
    await pumpSeat(tester, PlayerSeat(player: makePlayer()));

    expect(find.text('🐸'), findsOneWidget);
    expect(find.text('Luna'), findsOneWidget);
    expect(find.text('990'), findsOneWidget);
    expect(find.text('Suit 20'), findsOneWidget);
    expect(find.byType(PlayingCardWidget), findsNothing);
    expect(avatarDecoration(tester).boxShadow, isNull);
  });

  testWidgets('un anneau entoure le joueur dont c\'est le tour', (
    tester,
  ) async {
    await pumpSeat(tester, PlayerSeat(player: makePlayer(), isTurn: true));

    expect(avatarDecoration(tester).boxShadow, hasLength(2));
  });

  testWidgets('un joueur couché ou éliminé est atténué', (tester) async {
    await pumpSeat(tester, PlayerSeat(player: makePlayer()..folded = true));
    expect(seatOpacity(tester), 0.35);

    await pumpSeat(
      tester,
      PlayerSeat(
        player: makePlayer()
          ..folded = true
          ..eliminated = true,
      ),
    );
    expect(seatOpacity(tester), 0.18);
  });

  testWidgets('en tête-à-tête, le dealer porte aussi le badge SB', (
    tester,
  ) async {
    await pumpSeat(
      tester,
      PlayerSeat(player: makePlayer(), isDealer: true, isSmallBlind: true),
    );

    expect(find.text('D'), findsOneWidget);
    expect(find.text('SB'), findsOneWidget);
    expect(find.text('BB'), findsNothing);
  });

  testWidgets('au showdown, le siège montre la main et le résultat', (
    tester,
  ) async {
    final player = makePlayer()
      ..holeCards = const [
        PlayingCard(14, Suit.hearts),
        PlayingCard(14, Suit.clubs),
      ]
      // Même éliminé, le joueur reste visible pendant qu'il montre sa main
      ..eliminated = true;

    await pumpSeat(
      tester,
      PlayerSeat(
        player: player,
        showdown: const SeatShowdown(
          handLabel: 'Paire',
          result: SeatResult.winner,
          winnings: 200,
        ),
      ),
    );

    expect(find.byType(PlayingCardWidget), findsNWidgets(2));
    expect(find.text('Paire'), findsOneWidget);
    expect(find.text('Gagne 200'), findsOneWidget);
    expect(seatOpacity(tester), 1);
  });
}