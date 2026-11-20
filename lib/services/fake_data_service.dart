import '../models/game_config.dart';
import '../models/player.dart';

// Données fictives de départ
class FakeDataService {
  FakeDataService._();

  // Salon de test
  static final GameConfig config = GameConfig.fromStack(
    name: 'Les Amis',
    maxPlayers: 6,
    startingStack: 1000,
  );

  // Bots 
  static const List<(String, String) > _bots = [
    ('Luna', '🐸'),
    ('Eli', '😈'),
    ('Remi', '🐵'),
    ('Emma', '🐙'),
    ('Anna', '🐼'),
  ];

  // Crée les joueurs
  static List<Player> players({String heroName = 'Joueur'}) {
    final stack = config.startingStack;
    return [
      Player(id: 0, name: heroName, emoji: '🦊', stack: stack, isHuman: true),
      for (var i=0; i < _bots.length; i++)
        Player(id: i+1, name: _bots[i].$1, emoji: _bots[i].$2, stack: stack),
    ];
  }
}