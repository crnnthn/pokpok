import 'package:client/theme/app_colors.dart';
import 'package:client/theme/app_texts_sizes.dart';
import 'package:client/widgets/emojie_list_choice.dart';
import 'package:client/widgets/text_input.dart';
import 'package:flutter/material.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: Padding(
            padding: EdgeInsetsGeometry.all(25),
            child: Align(
              alignment: Alignment.topLeft,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Bienvenue sur",
                    style: TextStyle(
                      color: AppColors.text,
                      fontSize: AppTextSizes.title,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Row(
                    children: [
                      Text(
                        "Pok",
                        style: TextStyle(
                          color: AppColors.text,
                          fontSize: AppTextSizes.title,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        "Pok",
                        style: TextStyle(
                          color: AppColors.primary,
                          fontSize: AppTextSizes.title,
                          fontWeight: FontWeight.bold,
                        ),
                      )
                    ],
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Text(
                      "Pas de compte : choisis un pseudo et un avatar, c'est tout.",
                      style: TextStyle(
                        color: AppColors.secondaryText,
                        fontSize: AppTextSizes.text,
                      ),
                    )
                  ),
                  TextInput(),
                  SizedBox(height: 12),
                  Expanded(child: EmojieListChoice(),),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
