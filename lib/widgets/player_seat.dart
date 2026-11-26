import 'package:flutter/material.dart';

import '../models/player.dart';
import '../models/seat_showdown.dart';
import '../theme/app_colors.dart';
import '../theme/app_surfaces.dart';
import 'playing_card_widget.dart';

// Place d'un adversaire autour de la table
class PlayerSeat extends StatelessWidget {
  const PlayerSeat({
    super.key,
    required this.player,
    this.isTurn = false,
    this.isDealer = false,
    this.isSmallBlind = false,
    this.isBigBlind = false,
    this.showdown,
  });

  final Player player;
  final bool isTurn;

  // Rôles pour la main en cours
  final bool isDealer;
  final bool isSmallBlind;
  final bool isBigBlind;

  // Renseigné si le joueur montre ses cartes
  final SeatShowdown? showdown;

  static const double width = 68;
  static const double _avatarSize = 54;
  static const Color _smallBlindColor = Color(0xFFCFCFD4);

  // Joueur éliminé reste visible pendant que sa main est montrée
  double get _opacity {
    if (showdown != null) return 1;
    if (player.eliminated) return 0.18;
    if (player.folded) return 0.35;
    return 1;
  }

  @override
  Widget build(BuildContext context) {
    final shown = showdown;

    // Taille du texte
    return MediaQuery.withNoTextScaling(
      child: AnimatedOpacity(
        opacity: _opacity,
        duration: const Duration(milliseconds: 300),
        child: SizedBox(
          width: width,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildAvatar(),
              const SizedBox(height: 5),
              _line(
                player.name,
                size: 11,
                weight: FontWeight.w500,
                color: AppColors.secondaryText,
              ),
              _line(
                '${player.stack}',
                size: 15,
                weight: FontWeight.w700,
                color: AppColors.text,
                height: 1.1,
              ),
              const SizedBox(height: 3),

              // Hauteur minimale réservé
              ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 14),
                child: _line(
                  player.lastAction,
                  size: 10.5,
                  weight: FontWeight.w600,
                  color: player.folded
                      ? AppColors.secondaryText
                      : AppColors.primary,
                ),
              ),
              if (shown != null) ..._buildShowdown(shown),
            ],
          ),
        ),
      ),
    );
  }

  // Avatar rond
  Widget _buildAvatar() {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: _avatarSize,
          height: _avatarSize,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppSurfaces.surface2,
            shape: BoxShape.circle,

            // La seconde ombre recouvre la première : l'anneau orange
            boxShadow: isTurn
                ? const [
                    BoxShadow(color: AppColors.primary, spreadRadius: 5),
                    BoxShadow(color: AppColors.background, spreadRadius: 3),
                  ]
                : null,
          ),
          child: Text(player.emoji, style: const TextStyle(fontSize: 30)),
        ),
        if (isDealer)
          Positioned(top: -4, right: 2, child: _badge('D', AppColors.text)),
        if (isSmallBlind)
          Positioned(top: -4, left: 2, child: _badge('SB', _smallBlindColor)),
        if (isBigBlind)
          Positioned(top: -4, left: 2, child: _badge('BB', AppColors.primary)),
      ],
    );
  }

  // Pastille de rôle
  Widget _badge(String label, Color color) {
    return Container(
      height: 20,
      constraints: const BoxConstraints(minWidth: 20),
      padding: const EdgeInsets.symmetric(horizontal: 3),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.background, width: 2),
      ),
      child: Center(
        widthFactor: 1,
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w800,
            height: 1,
            color: AppColors.background,
          ),
        ),
      ),
    );
  }

  // Cartes montrées, nom de la main et résultat
  List<Widget> _buildShowdown(SeatShowdown shown) {
    final handLabel = shown.handLabel;
    final resultText = shown.resultText;

    return [
      const SizedBox(height: 4),
      Row(
        mainAxisAlignment: MainAxisAlignment.center,
        spacing: 2,
        children: [
          for (final card in player.holeCards)
            PlayingCardWidget(card: card, size: CardSize.extraSmall),
        ],
      ),
      if (handLabel != null) ...[
        const SizedBox(height: 2),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
          decoration: BoxDecoration(
            color: shown.isHighlighted
                ? AppColors.primary
                : AppSurfaces.surface2,
            borderRadius: BorderRadius.circular(6),
          ),
          child: _line(
            handLabel,
            size: 10,
            weight: FontWeight.w600,
            maxLines: 2,
            color: shown.isHighlighted
                ? AppColors.background
                : shown.result == SeatResult.beaten
                ? AppColors.secondaryText
                : AppColors.text,
          ),
        ),
      ],
      if (resultText != null) ...[
        const SizedBox(height: 2),
        _line(
          resultText,
          size: 10.5,
          weight: FontWeight.w600,
          maxLines: 2,
          color: AppColors.primary,
        ),
      ],
    ];
  }

  // Ligne de texte centrée
  Widget _line(
    String text, {
    required double size,
    required FontWeight weight,
    required Color color,
    double height = 1.21,
    int maxLines = 1,
  }) {
    return Text(
      text,
      maxLines: maxLines,
      overflow: TextOverflow.ellipsis,
      textAlign: TextAlign.center,
      style: TextStyle(
        fontSize: size,
        fontWeight: weight,
        height: height,
        color: color,
      ),
    );
  }
}
