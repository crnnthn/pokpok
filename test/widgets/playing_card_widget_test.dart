import 'package:client/models/playing_card.dart';
import 'package:client/models/suit.dart';
import 'package:client/theme/app_card_colors.dart';
import 'package:client/widgets/playing_card_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// Affiche un widget seul, au centre d'un écran de test
Future<void> pumpCard(WidgetTester tester, Widget card) => tester.pumpWidget(
  MaterialApp(
    home: Scaffold(body: Center(child: card)),
  ),
);

void main() {
  testWidgets('une carte affiche son rang et son symbole en rouge', (
    tester,
  ) async {
    await pumpCard(
      tester,
      const PlayingCardWidget(card: PlayingCard(14, Suit.hearts)),
    );

    expect(find.text('A'), findsOneWidget);
    expect(find.text('♥'), findsOneWidget);

    final rank = tester.widget<Text>(find.text('A'));
    expect(rank.style!.color, AppCardColors.red);
  });

  testWidgets('une carte grisée utilise les couleurs atténuées', (
    tester,
  ) async {
    await pumpCard(
      tester,
      const PlayingCardWidget(
        card: PlayingCard(13, Suit.spades),
        dimmed: true,
      ),
    );

    final rank = tester.widget<Text>(find.text('K'));
    expect(rank.style!.color, AppCardColors.dimInk);
  });

  testWidgets('la taille du widget suit la variante choisie', (tester) async {
    await pumpCard(tester, const PlayingCardWidget.back(size: CardSize.hero));

    expect(
      tester.getSize(find.byType(PlayingCardWidget)),
      const Size(80, 112),
    );
  });

  testWidgets('seul le dos est dessiné avec des rayures, sans texte', (
    tester,
  ) async {
    await pumpCard(
      tester,
      const Row(
        children: [PlayingCardWidget.back(), PlayingCardWidget.empty()],
      ),
    );

    expect(find.byType(Text), findsNothing);

    // Le ClipRRect n'existe que dans le dos : on doit en trouver un seul
    expect(
      find.descendant(
        of: find.byType(PlayingCardWidget),
        matching: find.byType(ClipRRect),
      ),
      findsOneWidget,
    );
  });
}