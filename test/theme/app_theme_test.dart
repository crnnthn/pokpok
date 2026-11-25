import 'package:client/theme/app_colors.dart';
import 'package:client/theme/app_fonts.dart';
import 'package:client/theme/app_theme.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('le thème sombre utilise les tokens du projet', () {
    final theme = AppTheme.dark();

    expect(theme.scaffoldBackgroundColor, AppColors.background);
    expect(theme.colorScheme.primary, AppColors.primary);
    expect(theme.textTheme.bodyMedium?.fontFamily, AppFonts.family);
  });
}