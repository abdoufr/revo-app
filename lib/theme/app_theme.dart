import 'package:flutter/material.dart';


class AppTheme {
  // Purxx Style Colors (Light Theme)
  static const Color primaryRed = Color(0xFFFF5722); // Reverted to Orange as requested
  static const Color primaryRedLight = Color(0xFFFF8A65);
  static const Color bgWhite = Color(0xFFFFFFFF);
  static const Color bgLightGray = Color(0xFFF9F9F9);
  static const Color textDark = Color(0xFF1E1E1E);
  static const Color textLightGrey = Color(0xFF9E9E9E);
  static const Color borderLight = Color(0xFFEEEEEE);

  // Dark Theme Colors
  static const Color bgDark = Color(0xFF121212);
  static const Color bgDarker = Color(0xFF0A0A0A);
  static const Color bgDarkCard = Color(0xFF1E1E1E);
  static const Color textWhite = Color(0xFFFFFFFF);
  static const Color textDarkGrey = Color(0xFFAAAAAA);
  static const Color borderDark = Color(0xFF333333);

  // Status Colors
  static const Color success = Color(0xFF10B981);
  static const Color error = Color(0xFFEF4444);
  
  static ThemeData get lightTheme {
    return ThemeData(
      brightness: Brightness.light,
      scaffoldBackgroundColor: bgLightGray,
      primaryColor: primaryRed,
      colorScheme: const ColorScheme.light(
        primary: primaryRed,
        secondary: primaryRedLight,
        surface: bgWhite,
        error: error,
      ),
      textTheme: ThemeData.light().textTheme.copyWith(
        displayLarge: const TextStyle(fontFamily: 'Poppins', color: textDark, fontWeight: FontWeight.w800, letterSpacing: -1),
        displayMedium: const TextStyle(fontFamily: 'Poppins', color: textDark, fontWeight: FontWeight.w700, letterSpacing: -0.5),
        bodyLarge: const TextStyle(fontFamily: 'Poppins', color: textDark, fontWeight: FontWeight.w500),
        bodyMedium: const TextStyle(fontFamily: 'Poppins', color: textLightGrey, fontWeight: FontWeight.w400),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: textDark),
        titleTextStyle: TextStyle(color: textDark, fontSize: 20, fontWeight: FontWeight.bold),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: bgWhite,
        hintStyle: const TextStyle(fontFamily: 'Poppins', color: textLightGrey),
        contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: borderLight),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: borderLight),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: primaryRed, width: 2),
        ),
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: bgDark,
      primaryColor: primaryRed,
      colorScheme: const ColorScheme.dark(
        primary: primaryRed,
        secondary: primaryRedLight,
        surface: bgDarkCard,
        error: error,
      ),
      textTheme: ThemeData.dark().textTheme.copyWith(
        displayLarge: const TextStyle(fontFamily: 'Poppins', color: textWhite, fontWeight: FontWeight.w800, letterSpacing: -1),
        displayMedium: const TextStyle(fontFamily: 'Poppins', color: textWhite, fontWeight: FontWeight.w700, letterSpacing: -0.5),
        bodyLarge: const TextStyle(fontFamily: 'Poppins', color: textWhite, fontWeight: FontWeight.w500),
        bodyMedium: const TextStyle(fontFamily: 'Poppins', color: textDarkGrey, fontWeight: FontWeight.w400),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: textWhite),
        titleTextStyle: TextStyle(color: textWhite, fontSize: 20, fontWeight: FontWeight.bold),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: bgDarkCard,
        hintStyle: const TextStyle(fontFamily: 'Poppins', color: textDarkGrey),
        contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: borderDark),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: borderDark),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: primaryRed, width: 2),
        ),
      ),
    );
  }
}

// Modern Soft Card adapting to theme
class SoftCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final double borderRadius;
  final VoidCallback? onTap;

  const SoftCard({
    Key? key,
    required this.child,
    this.padding = const EdgeInsets.all(24),
    this.borderRadius = 24,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: padding,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(borderRadius),
          border: Border.all(color: isDark ? AppTheme.borderDark : AppTheme.borderLight),
          boxShadow: isDark ? [] : [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 20,
              offset: const Offset(0, 5),
            )
          ],
        ),
        child: child,
      ),
    );
  }
}

// Main Primary Button
class PrimaryButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final bool isLoading;

  const PrimaryButton({
    Key? key,
    required this.text,
    required this.onPressed,
    this.isLoading = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 60,
      decoration: BoxDecoration(
        color: AppTheme.primaryRed,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryRed.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        child: isLoading 
            ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
            : Text(
                text,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
      ),
    );
  }
}
