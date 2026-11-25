import 'dart:math';

import 'package:flutter/material.dart';

import '../models/playing_card.dart';
import '../theme/app_card_colors.dart';
import '../theme/app_fonts.dart';

// Les tailles de carte
enum CardSize {
  // Cartes communes au centre de la table
  standard(
    width: 60,
    height: 84,
    radius: 10,
    rankTop: 6,
    rankLeft: 8,
    rankSize: 20,
    suitSize: 34,
    suitShift: 6,
    hasShadow: true,
  ),

  // Les cartes du joueur
  hero(
    width: 80,
    height: 112,
    radius: 14,
    rankTop: 9,
    rankLeft: 12,
    rankSize: 28,
    suitSize: 50,
    suitShift: 8,
    hasShadow: true,
  ),

  // Mains montrées au showdown
  mini(
    width: 30,
    height: 42,
    radius: 6,
    rankTop: 4,
    rankLeft: 5,
    rankSize: 12,
    suitSize: 18,
    suitShift: 5,
    hasShadow: false,
  ),

  // Grille des combinaisons
  extraSmall(
    width: 26,
    height: 36,
    radius: 5,
    rankTop: 3,
    rankLeft: 4,
    rankSize: 10,
    suitSize: 16,
    suitShift: 4,
    hasShadow: false,
  );

  const CardSize({
    required this.width,
    required this.height,
    required this.radius,
    required this.rankTop,
    required this.rankLeft,
    required this.rankSize,
    required this.suitSize,
    required this.suitShift,
    required this.hasShadow,
  });

  final double width;
  final double height;
  final double radius;

  // Position du rang, depuis le coin haut gauche
  final double rankTop;
  final double rankLeft;

  final double rankSize;
  final double suitSize;

  // Marge au-dessus de la zone dans laquelle le symbole est centré
  final double suitShift;

  final bool hasShadow;
}

// Ce que montre la carte
enum _CardKind { face, back, empty }

// Une carte à jouer : face visible, dos ou emplacement vide
class PlayingCardWidget extends StatelessWidget {
  // Face visible
  const PlayingCardWidget({
    super.key,
    required PlayingCard this.card,
    this.size = CardSize.standard,
    this.dimmed = false,
  }) : _kind = _CardKind.face;

  // Dos de la carte
  const PlayingCardWidget.back({super.key, this.size = CardSize.standard})
    : card = null,
      dimmed = false,
      _kind = _CardKind.back;

  // Emplacement d'un carte commune non révélée
  const PlayingCardWidget.empty({super.key, this.size = CardSize.standard})
    : card = null,
      dimmed = false,
      _kind = _CardKind.empty;

  final PlayingCard? card;
  final CardSize size;
  final bool dimmed;
  final _CardKind _kind;

  // Les ombres
  static const List<BoxShadow> _shadow = [
    BoxShadow(color: Color(0x66000000), offset: Offset(-4, 0), blurRadius: 10),
    BoxShadow(color: Color(0x44000000), offset: Offset(0, 2), blurRadius: 6),
  ];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size.width,
      height: size.height,
      child: switch (_kind) {
        _CardKind.face => _buildFace(card!),
        _CardKind.back => _buildBack(),
        _CardKind.empty => CustomPaint(
          painter: _DashedBorderPainter(size.radius),
        ),
      },
    );
  }

  Widget _buildFace(PlayingCard card) {
    final color = card.suit.isRed
        ? (dimmed ? AppCardColors.dimRed : AppCardColors.red)
        : (dimmed ? AppCardColors.dimInk : AppCardColors.ink);

    return Container(
      decoration: BoxDecoration(
        color: dimmed ? AppCardColors.dimFace : AppCardColors.face,
        borderRadius: BorderRadius.circular(size.radius),
        boxShadow: size.hasShadow ? _shadow : null,
      ),
      // Superpose le rang et le symbole
      child: Stack(
        // Rang en haut à gauche
        children: [
          Positioned(
            top: size.rankTop,
            left: size.rankLeft,
            child: _label(
              card.rankLabel,
              size.rankSize,
              FontWeight.w600,
              color,
            ),
          ),
          // Symbole centré
          Positioned.fill(
            child: Padding(
              padding: EdgeInsets.only(top: size.suitShift),
              child: Center(
                child: _label(
                  card.suit.symbole,
                  size.suitSize,
                  FontWeight.w500,
                  color,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Texte de la carte
  Widget _label(String text, double fontSize, FontWeight weight, Color color) {
    return Text(
      text,
      textScaler: TextScaler.noScaling,
      style: TextStyle(
        fontFamily: AppFonts.family,
        fontSize: fontSize,
        fontWeight: weight,
        height: 1.0,
        leadingDistribution: TextLeadingDistribution.even,
        color: color,
      ),
    );
  }

  Widget _buildBack() {
    const borderWidth = 3.0;

    return Container(
      padding: const EdgeInsets.all(borderWidth),
      decoration: BoxDecoration(
        color: AppCardColors.face,
        borderRadius: BorderRadius.circular(size.radius),
        boxShadow: size.hasShadow ? _shadow : null,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(max(0, size.radius - borderWidth)),
        child: const CustomPaint(painter: _StripesPainter()),
      ),
    );
  }
}

// Rayures diagonales au dos
class _StripesPainter extends CustomPainter {
  const _StripesPainter();

  static const double _period = 7;
  static const double _darkWith = 2;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = AppCardColors.backLight,
    );

    final stripe = Paint()
      ..color = AppCardColors.backDark
      ..strokeWidth = _darkWith;

    // Distance mesurée
    final diagonal = (size.width + size.height) / sqrt2;

    for (var d = 6.0; d <= diagonal + _darkWith; d += _period) {
      final c = d * sqrt2;
      canvas.drawLine(
        Offset(c, 0),
        Offset(c - size.height, size.height),
        stripe,
      );
    }
  }

  @override
  bool shouldRepaint(_StripesPainter oldDelegate) => false;
}

// Contour en pointillés
class _DashedBorderPainter extends CustomPainter {
  const _DashedBorderPainter(this.radius);

  final double radius;

  static const double _strokeWidth = 1.5;
  static const double _dash = 4;
  static const double _gap = 3;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppCardColors.emptyBorder
      ..style = PaintingStyle.stroke
      ..strokeWidth = _strokeWidth;

    final outline = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          (Offset.zero & size).deflate(_strokeWidth / 2),
          Radius.circular(radius),
        ),
      );

    // Découpe le contour en segments
    for (final metric in outline.computeMetrics()) {
      for (var start = 0.0; start < metric.length; start += _dash + _gap) {
        canvas.drawPath(metric.extractPath(start, start + _dash), paint);
      }
    }
  }

  @override
  bool shouldRepaint(_DashedBorderPainter oldDelegate) =>
      oldDelegate.radius != radius;
}
