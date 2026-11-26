import 'package:client/models/player_action.dart';
import 'package:flutter/material.dart';

import '../models/turn_options.dart';
import 'action_bar.dart';
import 'raise_panel.dart';
import 'turn_timer_bar.dart';

// Zone d'actions pendant le tour du joueur
class TurnActions extends StatefulWidget {
  const TurnActions({
    super.key,
    required this.options,
    required this.onAction,
    this.turnDuration = const Duration(seconds: 30),
  });

  final TurnOptions options;
  final ValueChanged<PlayerAction> onAction;
  final Duration turnDuration;

  @override
  State<TurnActions> createState() => _TurnActionsState();
}

class _TurnActionsState extends State<TurnActions>
    with SingleTickerProviderStateMixin {
  late final AnimationController _timer = AnimationController(
    vsync: this,
    duration: widget.turnDuration,
  );

  bool _raising = false;

  @override
  void initState() {
    super.initState();
    _timer.forward();
  }

  @override
  void dispose() {
    _timer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MediaQuery.withNoTextScaling(
      child: _raising
          ? RaisePanel(
              options: widget.options,
              onConfirm: (amount) =>
                  widget.onAction(PlayerAction.raiseTo(amount)),
              onCancel: () => setState(() => _raising = false),
            )
          : Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TurnTimerBar(elapsed: _timer),
                const SizedBox(height: 10),
                ActionBar(
                  options: widget.options,
                  onAction: widget.onAction,
                  onRaise: () => setState(() => _raising = true),
                ),
              ],
            ),
    );
  }
}
