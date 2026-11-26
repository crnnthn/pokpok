import 'package:flutter/material.dart';

import '../models/turn_options.dart';
import '../theme/app_colors.dart';
import '../theme/app_surfaces.dart';
import 'table_button.dart';

// Panneau de choix du montant de relance
class RaisePanel extends StatefulWidget {
  const RaisePanel({
    super.key,
    required this.options,
    required this.onConfirm,
    required this.onCancel,
  });

  final TurnOptions options;

  // Reçoit la mise totale choisie
  final ValueChanged<int> onConfirm;
  final VoidCallback onCancel;

  @override
  State<RaisePanel> createState() => _RaisePanelState();
}

class _RaisePanelState extends State<RaisePanel> {
  static const Color _panelBorder = Color(0xFF1F1F23);

  // Relance minimale
  late int _amount = widget.options.minRaiseTo;

  void _setAmount(num target) {
    setState(() => _amount = widget.options.clampRaise(target));
  }

  @override
  Widget build(BuildContext context) {
    final options = widget.options;
    final verb = options.isOpening ? 'Miser' : 'Relancer à';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppSurfaces.surface1,
        border: Border.all(color: _panelBorder),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            verb.toUpperCase(),
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.88,
              color: AppColors.secondaryText,
            ),
          ),
          Text(
            '$_amount',
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: AppColors.text,
            ),
          ),
          const SizedBox(height: 10),
          _buildSlider(options),
          const SizedBox(height: 10),
          Row(
            spacing: 6,
            children: [
              _quick('Min', options.minRaiseTo),
              _quick('½ pot', options.halfPotTo),
              _quick('Pot', options.potTo),
              _quick('Tapis', options.maxRaiseTo),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            spacing: 8,
            children: [
              SizedBox(
                width: 90,
                child: TableButton(
                  label: 'Retour',
                  height: 42,
                  radius: 12,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  onPressed: widget.onCancel,
                ),
              ),
              Expanded(
                child: TableButton(
                  label: '$verb $_amount',
                  height: 42,
                  radius: 12,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  background: AppColors.primary,
                  foreground: AppColors.background,
                  onPressed: () => widget.onConfirm(_amount),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Slider sur les boutons
  Widget _buildSlider(TurnOptions options) {
    return SliderTheme(
      data: SliderTheme.of(context).copyWith(
        trackHeight: 4,
        activeTrackColor: AppColors.primary,
        inactiveTrackColor: AppSurfaces.surface3,
        thumbColor: AppColors.primary,
        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
        overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
      ),
      child: SizedBox(
        height: 24,
        child: Slider(
          padding: EdgeInsets.zero,
          min: options.minRaiseTo.toDouble(),
          max: options.maxRaiseTo.toDouble(),
          value: _amount.toDouble(),
          onChanged: _setAmount,
        ),
      ),
    );
  }

  // Bouton raccourci
  Widget _quick(String label, int target) {
    return Expanded(
      child: TableButton(
        label: label,
        height: 34,
        radius: 10,
        fontSize: 12.5,
        fontWeight: FontWeight.w600,
        onPressed: () => _setAmount(target),
      ),
    );
  }
}
