import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_surfaces.dart';

// Chronomètre sous forme de barre
class TurnTimerBar extends StatelessWidget {
  const TurnTimerBar({super.key, required this.elapsed});

  // Part du temps écoulé, de 0 à 1
  final Animation<double> elapsed;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(2),
      child: Container(
        height: 3,
        width: double.infinity,
        color: AppSurfaces.surface2,
        alignment: Alignment.centerLeft,
        child: AnimatedBuilder(
          animation: elapsed,
          builder: (context, _) => FractionallySizedBox(
            widthFactor: 1 - elapsed.value,
            heightFactor: 1,
            child: const ColoredBox(color: AppColors.primary),
          ),
        ),
      ),
    );
  }
}