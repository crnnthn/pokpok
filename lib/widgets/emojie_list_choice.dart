import 'package:client/data/avatars.dart';
import 'package:client/theme/app_colors.dart';
import 'package:client/theme/app_texts_sizes.dart';
import 'package:client/widgets/emojie_card.dart';
import 'package:flutter/material.dart';

class EmojieListChoice extends StatelessWidget {
  const EmojieListChoice({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "AVATAR",
          style: TextStyle(
            color: AppColors.secondaryText,
            fontSize: AppTextSizes.subtitle,
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            child: SizedBox(
              width: double.infinity,
              child: Padding(
                padding: EdgeInsets.only(top: 8, bottom: 15),
                child: Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  runSpacing: 8,
                  children: avatars.map((emoji) {
                    return EmojieCard(emoji: emoji);
                  }).toList(),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
