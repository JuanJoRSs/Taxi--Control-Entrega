import 'package:flutter/material.dart';

final ValueNotifier<ThemeMode> temaGlobal = ValueNotifier(ThemeMode.light);

class TaxiTheme {
  //Paleta
  static const Color primaryDark = Color(0xFF1A2B4C); //Azul
  static const Color accentGold = Color(0xFFD4AF37);  //Ámbar
  static const Color backgroundLight = Color(0xFFF5F7FA); //Gris
  static const Color surfaceWhite = Color(0xFFFFFFFF);
  
  //Colores de estado
  static const Color textPrimary = Color(0xFF2C3E50);
  static const Color textSecondary = Color(0xFF7F8C8D);
  static const Color success = Color(0xFF27AE60);
  static const Color warning = Color(0xFFF39C12);
  static const Color error = Color(0xFFC0392B);

  //Estilos de texto
  static const TextStyle tituloAppBar = TextStyle(
    color: Colors.white,
    fontSize: 20,
    fontWeight: FontWeight.bold,
  );

  static const TextStyle textoBotonGrid = TextStyle(
    color: textPrimary,
    fontSize: 14,
    fontWeight: FontWeight.w500,
  );

  //Decoración 
  static const double radioTarjeta = 12.0;
  static BoxDecoration decoracionTarjeta = BoxDecoration(
    color: surfaceWhite,
    borderRadius: BorderRadius.circular(radioTarjeta),
    boxShadow: const [
      BoxShadow(
        color: Colors.black,
        blurRadius: 10,
        offset: Offset(0, 4),
      ),
    ],
  );

  // --- TEMA CLARO (DÍA) ---
  static final ThemeData temaClaro = ThemeData(
    brightness: Brightness.light,
    scaffoldBackgroundColor: backgroundLight,
    primaryColor: primaryDark,
    appBarTheme: const AppBarTheme(
      backgroundColor: primaryDark,
      foregroundColor: Colors.white,
      elevation: 0,
    ),
    colorScheme: const ColorScheme.light(
      primary: primaryDark,
      secondary: accentGold,
    ),
    cardColor: surfaceWhite,
  );

  // --- TEMA OSCURO (NOCHE) ---
  static final ThemeData temaOscuro = ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: const Color(0xFF121212),
    primaryColor: Colors.black,
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.black,
      foregroundColor: accentGold,
      elevation: 0,
    ),
    colorScheme: const ColorScheme.dark(
      primary: accentGold,
      secondary: accentGold,
      surface: Color(0xFF1E1E1E),
    ),
    cardColor: const Color(0xFF1E1E1E),
  );
}