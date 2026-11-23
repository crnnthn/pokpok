// Les types d'action

enum ActionType {fold, check, call, raise}

// Une action de jeu choisie
class PlayerAction {

  // Se coucher
  const PlayerAction.fold():this._(ActionType.fold);

  // Checker
  const PlayerAction.check():this._(ActionType.check);

  // Suivre
  const PlayerAction.callBet():this._(ActionType.call);

  //Relancer
  const PlayerAction.raiseTo(int amount):this._(ActionType.raise, amount);

  const PlayerAction._(this.type, [this.amount = 0]);

  final ActionType type;

  // Mise totale visée
  final int amount;
}