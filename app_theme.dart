import 'package:flutter/material.dart';

/// Tema oscuro Material 3 de EcoMarket.
///
/// Regla: los widgets NUNCA hardcodean colores; todo sale de
/// `Theme.of(context).colorScheme` / `textTheme` para mantener el contraste.
class AppTheme {
  AppTheme._();

  static final ColorScheme _scheme = ColorScheme.fromSeed(
    seedColor: const Color(0xFF2E7D32), // verde ecológico
    brightness: Brightness.dark,
  );

  static ThemeData get dark => ThemeData(
        useMaterial3: true,
        colorScheme: _scheme,
        scaffoldBackgroundColor: const Color(0xFF0F1512),
        appBarTheme: const AppBarTheme(centerTitle: false),
        // Flutter < 3.27: cambiar CardThemeData por CardTheme.
        cardTheme: CardThemeData(
          color: const Color(0xFF1A221D),
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFF1A221D),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
        snackBarTheme:
            const SnackBarThemeData(behavior: SnackBarBehavior.floating),
      );
}
