// Pilote le déroulement d'une partie
import 'dart:math';

import 'package:flutter/foundation.dart';

import '../models/deck.dart';
import '../models/game_config.dart';
import '../models/game_phase.dart';
import '../models/playing_card.dart';
import '../models/player.dart';


class GameController extends ChangeNotifier{
  GameController({
    required this.config,
    required List<Player> players,
    int? initialDealer,
    Deck Function() ? deckBuilder,
  }) : _players = players,
      // Par défaut un paquet mélangé
      _deckBuilder = deckBuilder ?? Deck.new,
      // Dealer de départ tié au hasard
      dealerIndex = initialDealer ?? Random().nextInt(players.length);
  
  // Paramètres de la partie
  final GameConfig config;

  final List<Player> _players;
  final Deck Function() _deckBuilder;
  late Deck _deck;

  // Cartes déjà révélées
  final List<PlayingCard> _board = [];

  // ---- État de la table, lu par l'interface ----

  // Siège du dealer
  int dealerIndex;

  // Siège SB et BB
  int smallBlindIndex = -1;
  int bigBlindIndex = -1;

  // Siège du joueur qui doit jouer
  int currentPlayerIndex = -1;

  // Phase en cours
  GamePhase phase = GamePhase.preflop;

  // Total de jetons dans le pot
  int pot = 0;

  // Mise la plus haute
  int currentBet = 0;

  // Montant minimal d'une relance
  int minRaise = 0;

  // Numéro de la la main
  int handNumber = 0;

  // Liste joueurs
  List<Player> get players => List.unmodifiable(_players);

  // Cartes communes
  List<PlayingCard> get board => List.unmodifiable(_board);

  // Joueurs encore en jeu
  int get activePlayerCount => _players.where((p) => !p.eliminated).length;

  // ---- Lancement d'une main ----

  // Démarre un nouvelle main
  void startHand() {
    final active = activePlayerCount;
    if (active < 2) {
      throw StateError('Il faut au moins 2 joueurs pour jouer une main');
    }
    handNumber++;
    for (final p in _players) {
      p.resetForNewHand();
    }
    _board.clear();
    pot = 0;
    phase = GamePhase.preflop;

    // Déplace le dealer
    dealerIndex = _nextActiveAfter(dealerIndex);

    //Placement des blinds.
    final int firstToAct;
    if (active == 2) {
      smallBlindIndex = dealerIndex;
      bigBlindIndex = _nextActiveAfter(smallBlindIndex);
      firstToAct = smallBlindIndex;
    } else {
      smallBlindIndex = _nextActiveAfter(dealerIndex);
      bigBlindIndex = _nextActiveAfter(smallBlindIndex);
      firstToAct = _nextActiveAfter(bigBlindIndex);
    }

    _deck = _deckBuilder();
    _dealHoleCards();

    _postBlind(_players[smallBlindIndex], config.smallBlind, 'SB');
    _postBlind(_players[bigBlindIndex], config.bigBlind, 'BB');

    currentBet = config.bigBlind;
    minRaise = config.bigBlind;
    currentPlayerIndex = firstToAct;

    notifyListeners();
  }

  // Distribue les mains
  void _dealHoleCards() {
    // Ordre de distribution : à partir de SB
    final order = <int>[];
    var seat = smallBlindIndex;
    do {
      order.add(seat);
      seat = _nextActiveAfter(seat);
    } while(seat != smallBlindIndex);

    for (var round = 0; round < 2; round++){
      for (final i in order) {
        _players[i].holeCards.add(_deck.draw());
      }
    }
  }

  // Fait payer les blind
  void _postBlind(Player player, int amount, String label) {
    final paid = _pay(player, amount);
    player.lastAction = '$label $paid';
  }

  // Déplace la mise vers le pot
  int _pay(Player player, int amount) {
    final paid = min(amount, player.stack);
    player.stack -= paid;
    player.bet += paid;
    pot += paid;
    return paid;
  }

  // Siège du joueur suivant
  int _nextActiveAfter(int from){
    var i = from;
    do {
      i = (i + 1) % _players.length;
    } while (_players[i].eliminated);
    return i;
  }
}