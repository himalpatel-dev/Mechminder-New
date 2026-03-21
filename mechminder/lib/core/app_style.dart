import 'package:flutter/material.dart';

class AppStyle {
  // --- Colors ---
  static const Color successGreen = Color(0xFF4CAF50);
  static const Color warningOrange = Color(0xFFFF9800);
  static const Color errorRed = Color(0xFFF44336);
  static const Color surfaceDark = Color(0xFF121212);
  static const Color cardDark = Color(0xFF1E1E1E);

  // --- Spacing & Borders ---
  static const double paddingPage = 20.0;
  static const double paddingSection = 16.0;
  static const double paddingItem = 12.0;
  static const double borderRadiusExtraLarge = 30.0;
  static const double borderRadiusLarge = 24.0;
  static const double borderRadiusMedium = 16.0;
  static const double borderRadiusSmall = 12.0;

  // --- Typography ---
  static TextStyle heading(BuildContext context, {Color? color}) => TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.bold,
    color: color ?? Theme.of(context).textTheme.bodyLarge?.color,
  );

  static TextStyle sectionHeader(BuildContext context) => TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.bold,
    color: Theme.of(context).primaryColor,
    letterSpacing: 1.2,
  );

  static const TextStyle cardTitle = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.bold,
  );

  static const TextStyle cardSubtitle = TextStyle(
    fontSize: 14,
    color: Colors.grey,
  );

  // --- Shared Decorations ---
  static BoxDecoration cardDecoration(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    return BoxDecoration(
      color: isDark ? cardDark : Colors.white,
      borderRadius: BorderRadius.circular(borderRadiusMedium),
      boxShadow: isDark
          ? []
          : [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 15,
                offset: const Offset(0, 5),
              ),
            ],
    );
  }

  static InputBorder inputBorder(Color color) => OutlineInputBorder(
    borderRadius: BorderRadius.circular(borderRadiusSmall),
    borderSide: BorderSide(color: color.withOpacity(0.3)),
  );
}
