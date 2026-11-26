import 'package:flutter/material.dart';

import '../models/player_action.dart';
import '../models/turn_options.dart';
import '../theme/app_colors.dart';
import '../theme/app_surfaces.dart';
import 'table_button.dart';

// Les quatres boutons affichés
class ActionBar extends StatelessWidget {
    const ActionBar({
        super.key,
        required this.options,
        required this.onAction,
        required this.onRaise,
    });

    final TurnOptions options;

// Action choisie
    final ValueChanged<PlayerAction> onAction;

// Ouverture du panneau de relance
    final VoidCallback onRaise;

    static const Color _foldText = Color(0xFFC9C9CD);
    static const Color _allInBorder = Color(0xFF5B4416);

    @override
    Widget build(BuildContext context) {
        return Row (
            spacing: 8,
            children: [
                Expanded(
                    flex: 100,
                    child: TableButton(
                        label: "Se coucher",
                        foreground: _foldText,
                        onPressed: () => onAction(const PlayerAction.fold()),
                    ),
                ),
                Expanded(
                    flex: 125,
                    child: _buildCallAction(),
                ),
                Expanded(
                    flex: 115,
                    child:TableButton(
                        label: options.isOpening ? 'Miser' : 'Relancer',
                        caption: options.canRaise ? 'min ${options.minRaiseTo}' : null,
                        onPressed: options.canRaise ? onRaise : null,
                    ),
                ),
                Expanded(
                    flex: 90,
                    child: TableButton(
                        label: 'Tapis',
                        caption: '${options.stack}',
                        background: AppSurfaces.accentDark,
                        foreground: AppColors.primary,
                        borderColor: _allInBorder,
                        onPressed: () => onAction(options.allIn),
                    ),
                ),
            ],
        );
    }

    // Vérifier si rien à payer
    Widget _buildCallAction() {
        final String label;
        if (options.canCheck) {
            label = 'Checker';
        } else {
            label = options.isCallAllIn ? 'Tapis' : 'Suivre';
        }

        return TableButton(
            label: label,
            caption: options.canCheck ? null : '${options.toCall}',
            background: AppColors.text,
            foreground: AppColors.background,
            onPressed: () => onAction(
                options.canCheck
                ? const PlayerAction.check()
                : const PlayerAction.callBet(),
            ),
        );
    }
}
