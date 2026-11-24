// Pilote le déroulement d'une partie
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import '../models/deck.dart';
import '../models/game_config.dart';
import '../models/game_phase.dart';
import '../models/playing_card.dart';
import '../models/player.dart';
import '../models/player_action.dart';
import '../models/hand_evaluator.dart';
import '../models/showdown_reveal.dart';

class GameController extends ChangeNotifier {
  GameController({
    required this.config,
    required List<Player> players,
    int? initialDealer,
    Deck Function()? deckBuilder,
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

  // JOueur qui doivent encore parler
  final Set<int> _pending = {};

  // Joueurs qui montrent leur main au showdown
  final List<Player> _showdownQueue = [];

  // Mains déjà révélées
  final List<ShowdownReveal> _reveals = [];

  // Gagnant(s) de la main / jetons gagnés
  List<Player> _winners = [];
  final Map<int, int> _winnings = {};

  // Vrai quand la main est terminé
  bool handFinished = false;

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

  // Nombre de relance dans le tour
  int raisesInRound = 0;

  // Compteur d'actions
  int actionCount = 0;

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

    // Efface les résultats de la main précédente
    _showdownQueue.clear();

    _reveals.clear();
    _winners = [];

    _winnings.clear();
    handFinished = false;

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

    // Ouvre le premier tour de mise
    _beginBettingRound(firstToAct);

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
    } while (seat != smallBlindIndex);

    for (var round = 0; round < 2; round++) {
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
  int _nextActiveAfter(int from) {
    var i = from;
    do {
      i = (i + 1) % _players.length;
    } while (_players[i].eliminated);
    return i;
  }

  // ---- Tour de mise ----

  // Le joueur dont c'st le tour
  Player? get currentPlayer =>
      currentPlayerIndex >= 0 ? _players[currentPlayerIndex] : null;

  // Jetons que [player] doit payer pour suivre
  int toCall(Player player) =>
      max(0, min(currentBet - player.bet, player.stack));

  // Plus petite mise pour une relance, plafonné au tapis
  int get minRaiseTo {
    final p = currentPlayer!;
    return min(p.bet + p.stack, currentBet + minRaise);
  }

  // Applique l'action du joueur courant
  void act(PlayerAction action) {
    final p = currentPlayer;
    if (p == null) {
      throw StateError('Aucun joueur ne peut agir actuellement');
    }

    switch (action.type) {
      case ActionType.fold:
        p.folded = true;
        p.lastAction = "Couché";
      case ActionType.check:
        if (toCall(p) > 0) {
          throw ArgumentError(
            'Impossible de checker : il faut suivre ou se coucher',
          );
        }
        p.lastAction = "Check";
      case ActionType.call:
        final paid = _pay(p, toCall(p));
        p.lastAction = paid == 0
            ? 'Check'
            : (p.stack == 0 ? 'Tapis $paid' : 'Suit $paid');
      case ActionType.raise:
        _raise(p, action.amount);
    }

    // Joueur a joué dans les temps
    p.consecutiveTimeouts = 0;
    actionCount++;

    // Ce joueur a parlé
    _pending.remove(currentPlayerIndex);
    _advanceTurn();
    notifyListeners();
  }

  // Applique une relance
  void _raise(Player p, int to) {
    final maxTo = p.bet + p.stack;
    if (to <= currentBet) {
      throw ArgumentError(
        'Une relance doit dépasser la mise actuelle ($currentBet)',
      );
    }
    if (to > maxTo) {
      throw ArgumentError('Mise supérieure au tapis ($maxTo)');
    }
    // Sous la relance minimale, seul le tapis complet est accepté
    if (to < currentBet + minRaise && to != maxTo) {
      throw ArgumentError('Relance minimale : ${currentBet + minRaise}');
    }

    // Après le flop, la première mise s'appelle « Mise », ensuite « Relance »
    final label = currentBet == 0 ? 'Mise' : 'Relance';
    _pay(p, to - p.bet);

    // La relance minimale suivante est au moins égale à cette augmentation
    minRaise = max(minRaise, p.bet - currentBet);
    currentBet = p.bet;
    raisesInRound++;
    p.lastAction = p.stack == 0 ? 'Tapis ${p.bet}' : '$label ${p.bet}';

    // Tous les autres joueurs capables d'agir doivent reparler en cas de relance
    _pending
      ..clear()
      ..addAll([
        for (var i = 0; i < _players.length; i++)
          if (i != currentPlayerIndex && _players[i].canAct) i,
      ]);
  }

  // Passer la main au prochain joueur / termine le tour
  void _advanceTurn() {
    // Tous les autres se sont couché
    if (_players.where((p) => p.inHand).length <= 1) {
      _enterShowdown();
      return;
    }

    if (_pending.isEmpty) {
      _endBettingRound();
    } else {
      currentPlayerIndex = _nextPendingSeat(currentPlayerIndex + 1);
    }
  }

  // Ouvre un tour de mise
  void _beginBettingRound(int fromSeat) {
    raisesInRound = 0;
    _pending
      ..clear()
      ..addAll([
        for (var i = 0; i < _players.length; i++)
          if (_players[i].canAct) i,
      ]);

    // Personne ne peut miser
    if (_pending.isEmpty) {
      _endBettingRound();
      return;
    }

    currentPlayerIndex = _nextPendingSeat(fromSeat);
  }

  // Terminer le tour
  void _endBettingRound() {
    for (final p in _players) {
      p.bet = 0;
      // Garder « Couché » et « Tapis » affichés
      if (p.inHand && p.stack > 0) p.lastAction = '';
    }
    currentBet = 0;
    minRaise = config.bigBlind;

    phase = switch (phase) {
      GamePhase.preflop => GamePhase.flop,
      GamePhase.flop => GamePhase.turn,
      GamePhase.turn => GamePhase.river,
      GamePhase.river || GamePhase.showdown => GamePhase.showdown,
    };

    // Révèle les cartes manquantes
    while (_board.length < phase.communityCards) {
      _board.add(_deck.draw());
    }

    if (phase == GamePhase.showdown) {
      _enterShowdown();
      return;
    }

    // Si aucun joueur ne peut miser
    if (_players.where((p) => p.canAct).length <= 1) {
      _endBettingRound();
      return;
    }

    // Après flop, le premier à parler est celui à gauche du dealer
    _beginBettingRound(_nextActiveAfter(dealerIndex));
  }

  // Prochain siège en attente
  int _nextPendingSeat(int from) {
    for (var i = 0; i < _players.length; i++) {
      final seat = (from + i) % _players.length;
      if (_pending.contains(seat)) return seat;
    }
    return -1;
  }

  // ---- Fin de main ----

  // Mains révélées
  List<ShowdownReveal> get reveals => List.unmodifiable(_reveals);

  // Gagnant(s) de la main
  List<Player> get winners => List.unmodifiable(_winners);

  // Jetons gagnés par chaque gagnant
  Map<int, int> get winnings => Map.unmodifiable(_winnings);

  //Ouvre la phase de fin de main
  void _enterShowdown() {
    phase = GamePhase.showdown;

    currentPlayerIndex = -1;

    _pending.clear();
    for (final p in _players) {
      p.bet = 0;
    }

    final contenders = _players.where((p) => p.inHand).toList();
    if (contenders.length == 1) {
      // Joueur seul : gagne sans avoir à montrer sa main
      _awardPot(contenders);
      return;
    }

    // Ordre de révélation
    final start = _nextActiveAfter(dealerIndex);
    _showdownQueue.clear();
    for (var i = 0; i < _players.length; i++) {
      final p = _players[(start + i) % _players.length];
      if (p.inHand) _showdownQueue.add(p);
    }
  }

  // Révèle la main du joueur suivant
  void revealNextHand(){
    if (phase != GamePhase.showdown || handFinished || _showdownQueue.isEmpty) {
      throw StateError('Aucune main à révéler');
    }

    final player = _showdownQueue[_reveals.length];
    final value = HandEvaluator.evaluate([...player.holeCards, ..._board]);

    // Gagnante si égale ou bat celles déjà révélées
    final isLeading = _reveals.every((r) => value.compareTo(r.value!) >= 0);

    player.updateBestHand(value);
    _reveals.add(
      ShowdownReveal(player:player, value: value, isLeading: isLeading),
    );

    // Dernière révélation
    if (_reveals.length == _showdownQueue.length) {
      final best = _reveals.map((r) => r.value!).reduce((a,b) => a.compareTo(b) >= 0 ? a :b);
      _awardPot([
        for (final r in _reveals)
          if (r.value!.compareTo(best) == 0) r.player,
      ]);
    }
    notifyListeners();
  }

  // Joueur resté seul choisit de montrer sa main
  void revealWinnerHand(){
    if (!handFinished || _showdownQueue.isNotEmpty || _reveals.isNotEmpty) {
      throw StateError('Seul un joueur resté seul peut montrer sa main');
    }
    final winner = _winners.first;
    final cards = [...winner.holeCards, ..._board];

    // Avant le flop
    final value = cards.length >= 5 ? HandEvaluator.evaluate(cards) : null;
    if (value != null) winner.updateBestHand(value);

    _reveals.add(ShowdownReveal(player: winner, value: value, isLeading: true));
    notifyListeners();
  }

  // Distribue le pot entre les gagnants
  void _awardPot(List<Player> winners) {
    final share = pot ~/ winners.length;
    final remainder = pot % winners.length;

    for (var i = 0; i < winners.length; i++) {
      final amount = share + (i == 0 ? remainder : 0);

      winners[i].setStack(winners[i].stack + amount);
      winners[i].handsWon++;

      _winnings[winners[i].id] = amount;
    }

    pot = 0;
    _winners = winners;
    handFinished = true;

    // Un joueur sans jeton est éliminé
    for (final p in _players) {
      if (!p.eliminated && p.stack == 0) {
        p.eliminated = true;
        p.lastAction = 'Éliminé';
      }
    }
  }

    // ---- Fin de partie et inactivité ----

  // Exclusion pour inactivité
  static const int maxConsecutiveTimeouts = 2;
  static const int maxTotalTimeouts = 3;

  // Vrai quand il ne reste plus qu'un joueur
  bool get isGameOver => activePlayerCount <= 1;

  // Le gagnant de la partie
  Player?get gameWinner {
    if (activePlayerCount != 1) return null;
    return _players.firstWhere((p) => !p.eliminated);
  }

  // Le joueur n'a pas joué à temps
  // Se couche automatique
  // Exclu au bout de 2 timeouts de suite, ou de 3 au total.
  void timeOutCurrentPlayer(){
    final p = currentPlayer;
    if (p == null) {
      throw StateError('Aucun joueur ne peut agir actuellement');
    }

    final consecutive = p.consecutiveTimeouts + 1;
    final total = p.totalTimeouts + 1;

    act(const PlayerAction.fold());
    p.consecutiveTimeouts = consecutive;
    p.totalTimeouts = total;

    if (consecutive >= maxConsecutiveTimeouts || total >= maxTotalTimeouts) {
      p.eliminated =true;
      p.lastAction = 'Exclu';
    }
    notifyListeners();
  }
}
