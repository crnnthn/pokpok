// Les 4 symboles d'un jeu de cartes
enum Suit {
  spades('♠', isRed:false),
  hearts('♥', isRed:true),
  diamonds('♦', isRed: true),
  clubs('♣', isRed:false);

  const Suit(this.symbole, {required this.isRed});

  // Symbile Unicode sur la carte
  final String symbole;

  final bool isRed;
}