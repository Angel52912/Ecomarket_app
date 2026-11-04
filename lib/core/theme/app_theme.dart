// NOTA (Rol 1): stub mínimo para desbloquear `flutter analyze` y la demo.
// El Rol 2 debe reemplazarlo por su tema oscuro Material 3 completo.
import 'package:flutter/material.dart';

class AppTheme {
  AppTheme._();

  static final ThemeData dark = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: ColorScheme.fromSeed(
      seedColor: Colors.green,
      brightness: Brightness.dark,
    ),
    appBarTheme: const AppBarTheme(centerTitle: true),
  );
}
