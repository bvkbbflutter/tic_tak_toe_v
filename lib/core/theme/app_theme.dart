import 'package:flutter/material.dart';

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData.light().copyWith(
      scaffoldBackgroundColor: Colors.grey.shade300,
      primaryColor: Colors.deepPurple,
      colorScheme: ColorScheme.light(
        primary: Colors.grey.shade300,
        inversePrimary: Colors.grey.shade100,
        secondary: Colors.grey.shade600,
        surface: Colors.grey.shade200,
        onSurface: Colors.black87,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.grey.shade300,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
        titleTextStyle: const TextStyle(
          color: Colors.black87,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData.dark().copyWith(
      scaffoldBackgroundColor: Colors.grey.shade900,
      primaryColor: Colors.deepPurpleAccent,
      colorScheme: ColorScheme.dark(
        primary: Colors.grey.shade900,
        inversePrimary: Colors.grey.shade800,
        secondary: Colors.black,
        surface: const Color(0xFF1E1E1E),
        onSurface: Colors.white,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.grey.shade900,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        titleTextStyle: const TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  static BoxDecoration neumorphicBox(
    BuildContext context, {
    double borderRadius = 12,
    bool isPressed = false,
    Color? customColor,
    Border? border,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseColor = customColor ?? (isDark ? Colors.grey.shade900 : Colors.grey.shade300);
    final darkShadow = isDark ? Colors.black.withOpacity(0.8) : Colors.grey.shade500;
    final lightShadow = isDark ? Colors.grey.shade800.withOpacity(0.6) : Colors.white;

    return BoxDecoration(
      color: baseColor,
      borderRadius: BorderRadius.circular(borderRadius),
      border: border,
      boxShadow: isPressed
          ? []
          : [
              BoxShadow(
                color: darkShadow,
                offset: const Offset(4, 4),
                blurRadius: 8,
              ),
              BoxShadow(
                color: lightShadow,
                offset: const Offset(-4, -4),
                blurRadius: 8,
              ),
            ],
    );
  }

  static BoxDecoration neumorphicInset(
    BuildContext context, {
    double borderRadius = 12,
    Color? customColor,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return BoxDecoration(
      color: customColor ?? (isDark ? Colors.grey.shade900 : Colors.grey.shade300),
      borderRadius: BorderRadius.circular(borderRadius),
      border: Border.all(
        color: isDark ? Colors.black54 : Colors.grey.shade400,
        width: 1.5,
      ),
    );
  }
}
