import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_surfaces.dart';

// Bouton de la table (texte et montant)
class TableButton extends StatelessWidget {
  const TableButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.caption,
    this.background = AppSurfaces.surface2,
    this.foreground = AppColors.text,
    this.borderColor,
    this.height = 54,
    this.radius = 15,
    this.fontSize = 13.5,
    this.fontWeight = FontWeight.w700,
  });

  final String label;

  // Sans action, le bouton est  grisé
  final VoidCallback? onPressed;

  // Texte sous le libellé
  final String? caption;

  final Color background;
  final Color foreground;
  final Color? borderColor;
  final double height;
  final double radius;
  final double fontSize;
  final FontWeight fontWeight;

  @override
  Widget build(BuildContext context) {
    final border = borderColor;
    final small = caption;
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(radius),
      side: border == null ? BorderSide.none : BorderSide(color: border),
    );

    return Opacity(
      opacity: onPressed == null ? 0.3 : 1,
      child: SizedBox(
        height: height,
        child: Material(
          color: background,
          shape: shape,
          child: InkWell(
            onTap: onPressed,
            customBorder: shape,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: Center(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        label,
                        style: TextStyle(
                          fontSize: fontSize,
                          fontWeight: fontWeight,
                          height: 1.15,
                          color: foreground,
                        ),
                      ),
                      if (small != null)
                        Text(
                          small,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            height: 1.15,
                            color: foreground.withValues(alpha: 0.7),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
