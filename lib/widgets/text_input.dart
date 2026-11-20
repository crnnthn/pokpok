import 'package:client/theme/app_colors.dart';
import 'package:client/theme/app_radius.dart';
import 'package:client/theme/app_texts_sizes.dart';
import 'package:flutter/material.dart';

class TextInput extends StatelessWidget {
  const TextInput({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 8,
      children: [
        Text(
          "PSEUDO",
          style: TextStyle(
            color: AppColors.secondaryText,
            fontSize: AppTextSizes.subtitle,
          ),
        ),
        TextField(
          style: const TextStyle(color: AppColors.text),
          decoration: InputDecoration(
            hintText: 'Ton pseudo',
            hintStyle: const TextStyle(
              color: AppColors.secondaryText,
            ),
            filled: true,
            fillColor: const Color(0xFF111113),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.medium),
            ),
          ),
        ),
      ],
    );
  }
}
