// Les différents combinaisons
enum HandCategory {
  highCard('Carte haute'),
  pair('Paire'),
  twoPair('Double paire'),
  threeOfAKind('Brelan'),
  straight('Quinte'),
  flush('Couleur'),
  fullHouse('Full'),
  fourOfAKind('Carré'),
  straightFlush('Quinte flush');

  const HandCategory(this.label);

  // Nom affiché à l'écran
  final String label;
}

// La valeur d'une main : sa catégorie + les valeurs qui départagent
// Exemples de [tiebreakers] :
// - Paire d'As, kickers K-9-7  → [14, 13, 9, 7]
// - Full aux Rois par les 3    → [13, 3]
// - Quinte à 5 (A-2-3-4-5)     → [5]

class HandValue implements Comparable<HandValue> {
  const HandValue(this.category, this.tiebreakers);

  final HandCategory category;
  final List<int> tiebreakers;

  // Quinte flush à l'As
  bool get isRoyalFlush => 
    category == HandCategory.straightFlush && tiebreakers.first == 14;
  
  // Nom du combo du joueur
  String get label => isRoyalFlush ? 'Quinte flush royale' : category.label;
  
  // Compare deux mains : 
  //  - négatif si cette main est plus faible
  //  - positif si elle est plus forte
  //  - 0 en cas d'égalité parfaite (le pot est partagé)
  @override
  int compareTo(HandValue other) {
    final byCategory = category.index.compareTo(other.category.index);
    if (byCategory != 0) return byCategory;

    for (var i =0; i < tiebreakers.length && i < other.tiebreakers.length; i++) {
      final diff = tiebreakers[i].compareTo(other.tiebreakers[i]);
      if (diff != 0) return diff;
    }
    return 0;
  }

  @override
  String toString() => '$label $tiebreakers';
}