import 'package:client/models/player_action.dart';
import 'package:client/models/turn_options.dart';
import 'package:client/widgets/turn_actions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const facingBet = TurnOptions(
  stack: 990,
  bet: 10,
  toCall: 10,
  currentBet: 20,
  minRaiseTo: 40,
  pot: 30,
  step: 10,
);

const nothingToPay = TurnOptions(
  stack: 980,
  bet: 0,
  toCall: 0,
  currentBet: 0,
  minRaiseTo: 20,
  pot: 40,
  step: 10,
);

// Affiche la zone d'actions à la largeur qu'elle a sur la table
Future<void> pumpActions(
  WidgetTester tester,
  TurnOptions options,
  List<PlayerAction> chosen,
) => tester.pumpWidget(
  MaterialApp(
    home: Scaffold(
      body: Center(
        child: SizedBox(
          width: 362,
          child: TurnActions(options: options, onAction: chosen.add),
        ),
      ),
    ),
  ),
);

// Part de la barre encore remplie
double remaining(WidgetTester tester) => tester
    .widget<FractionallySizedBox>(find.byType(FractionallySizedBox))
    .widthFactor!;

void main() {
  testWidgets('face à une mise, le joueur peut suivre', (tester) async {
    final chosen = <PlayerAction>[];
    await pumpActions(tester, facingBet, chosen);

    expect(find.text('Se coucher'), findsOneWidget);
    expect(find.text('min 40'), findsOneWidget);
    expect(find.text('990'), findsOneWidget);

    await tester.tap(find.text('Suivre'));
    expect(chosen.single.type, ActionType.call);
  });

  testWidgets('sans mise à payer, le joueur peut checker ou miser', (
    tester,
  ) async {
    final chosen = <PlayerAction>[];
    await pumpActions(tester, nothingToPay, chosen);

    expect(find.text('Miser'), findsOneWidget);
    expect(find.text('Suivre'), findsNothing);

    await tester.tap(find.text('Checker'));
    expect(chosen.single.type, ActionType.check);
  });

  testWidgets('le panneau de relance envoie le montant choisi', (
    tester,
  ) async {
    final chosen = <PlayerAction>[];
    await pumpActions(tester, facingBet, chosen);

    await tester.tap(find.text('Relancer'));
    await tester.pump();
    expect(find.text('Relancer à 40'), findsOneWidget);

    await tester.tap(find.text('Pot'));
    await tester.pump();
    await tester.tap(find.text('Relancer à 60'));

    expect(chosen.single.type, ActionType.raise);
    expect(chosen.single.amount, 60);
  });

  testWidgets('le timer continue pendant le choix d\'une relance', (
    tester,
  ) async {
    await pumpActions(tester, facingBet, []);
    // Cette première image démarre le chronomètre de l'animation
    await tester.pump();

    await tester.pump(const Duration(seconds: 15));
    expect(remaining(tester), closeTo(0.5, 0.01));

    await tester.tap(find.text('Relancer'));
    await tester.pump(const Duration(seconds: 5));
    await tester.tap(find.text('Retour'));
    await tester.pump();

    expect(remaining(tester), closeTo(1 / 3, 0.01));
  });
}