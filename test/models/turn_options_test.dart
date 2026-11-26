import 'package:client/models/player_action.dart';
import 'package:client/models/turn_options.dart';
import 'package:flutter_test/flutter_test.dart';

// Au pré-flop, le joueur a posé la petite blind (10) face à la grosse (20)
TurnOptions options({int stack = 990}) => TurnOptions(
  stack: stack,
  bet: 10,
  toCall: 10,
  currentBet: 20,
  minRaiseTo: 40,
  pot: 30,
  step: 10,
);

void main() {
  test('face à une mise, le joueur peut suivre ou relancer', () {
    expect(options().canCheck, isFalse);
    expect(options().canRaise, isTrue);
    expect(options().isOpening, isFalse);
    expect(options().maxRaiseTo, 1000);
  });

  test('les montants sont arrondis et restent dans les limites', () {
    expect(options().halfPotTo, 40);
    expect(options().potTo, 60);
    expect(options().clampRaise(5), 40);
    expect(options().clampRaise(57), 60);
    expect(options().clampRaise(5000), 1000);
  });

  test('le tapis est accessible même hors du pas des mises', () {
    expect(options(stack: 983).clampRaise(993), 993);
    expect(options(stack: 983).allIn.amount, 993);
  });

  test('avec un petit tapis, faire tapis revient à suivre', () {
    const short = TurnOptions(
      stack: 15,
      bet: 0,
      toCall: 15,
      currentBet: 100,
      minRaiseTo: 15,
      pot: 150,
      step: 10,
    );

    expect(short.canRaise, isFalse);
    expect(short.isCallAllIn, isTrue);
    expect(short.allIn.type, ActionType.call);
  });
}