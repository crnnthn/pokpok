import 'package:client/theme/app_colors.dart';
import 'package:client/theme/app_radius.dart';
import 'package:client/theme/app_texts_sizes.dart';
import 'package:flutter/material.dart';

class EmojieCard extends StatelessWidget {
  final String emoji;

  const EmojieCard({
    super.key,
    required this.emoji,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.primary, width: 1),
        borderRadius: BorderRadius.circular(AppRadius.medium),
      ),
      child: Text(
        emoji,
        style: const TextStyle(fontSize: AppTextSizes.heading),
      ),
    );
  }
}
