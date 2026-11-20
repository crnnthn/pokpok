// Paramètres de partie
class GameConfig {
  const GameConfig({
    required this.name,
    required this.maxPlayers,
    required this.startingStack,
    required this.smallBlind,
    required this.bigBlind,
    this.turnSeconds = 30,
  }) : assert(maxPlayers >= minPlayers && maxPlayers <= absoluteMaxPlayers);

  // Construit une config et déduit les blinds à partir du tapis de départ
  factory GameConfig.fromStack({
    required String name,
    required int maxPlayers,
    required int startingStack,
  }) {
    final (sb, bb) = blindsFor(startingStack);
    return GameConfig(
      name: name,
      maxPlayers: maxPlayers,
      startingStack: startingStack,
      smallBlind: sb,
      bigBlind: bb
    );
  }

  // Limites de joueurs
  static const int minPlayers = 3;
  static const int absoluteMaxPlayers = 6;

  // Tapis de départ
  static const Map<int, (int, int)> _blindsByStack = {
    500: (5, 10),
    1000: (10, 20),
    2000: (20, 40),
    5000: (50, 100),
  };

  // Associe les blinds au tapis
  static (int, int) blindsFor(int startingStack) {
    final blinds = _blindsByStack[startingStack];
    if (blinds == null) {
      throw ArgumentError('Tapis de départ nin supporté : $startingStack');
    }
    return blinds;
  }

  // Nom du salon
  final String name;

  // Nombre max de joueurs
  final int maxPlayers;

  // Tapis de départ
  final int startingStack;

  // SB & BB
  final int smallBlind;
  final int bigBlind;

  // Temps d'un tour
  final int turnSeconds;
}