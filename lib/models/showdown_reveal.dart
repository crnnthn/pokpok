import 'hand_value.dart';
import 'player.dart';

// Main révélée
class ShowdownReveal {
  const ShowdownReveal({
    required this.player,
    required this.value,
    required this.isLeading,
  });

  // Le joueur qui montre ses cartes
  final Player player;

  // La valeur de sa main
  final HandValue? value;

  // Vrai si cette main égale ou bat toutes celles déjà montrées
  final bool isLeading;
}