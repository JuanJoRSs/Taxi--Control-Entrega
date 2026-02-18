import 'package:flutter/material.dart';

class TaxiTheme {
  // --- PALETA DE COLORES (TOKENS DE COLOR) ---

  // Un azul "eléctrico-profesional", ni muy oscuro ni muy claro.
  static const Color azulPrincipal = Color(0xFF1A73E8);

  // Un blanco con un toque de gris (Off-white) para no cansar la vista.
  static const Color fondoApp = Color(0xFFF9FAFB);

  static const Color blancoPuro = Colors.white;
  static const Color grisTextoPrincipal = Color(0xFF202124);
  static const Color grisTextoSecundario = Color(0xFF5F6368);
  static const Color grisBordes = Color(0xFFDADCE0);

  // Colores de estado (Semáforo)
  static const Color alerta = Color(
    0xFFD93025,
  ); // Rojo para tráfico/emergencias
  static const Color exito = Color(
    0xFF188038,
  ); // Verde para gasolineras/activos
  static const Color aviso = Color(
    0xFFF9AB00,
  ); // Naranja para liquidación/avisos


  static const double radioBoton = 12.0;
  static const double radioTarjeta = 16.0;

  static List<BoxShadow> sombraSuave = [
    BoxShadow(
      color: Colors.black.withOpacity(0.04),
      blurRadius: 12,
      offset: const Offset(0, 4),
    ),
  ];

  // --- TOKENS DE TEXTO (TIPOGRAFÍA) ---

  static const TextStyle tituloAppBar = TextStyle(
    fontSize: 19,
    fontWeight: FontWeight.w700,
    color: blancoPuro,
    letterSpacing: 0.5,
  );

  static const TextStyle textoBotonGrid = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w600,
    color: grisTextoPrincipal,
  );

  static const TextStyle subtitulo = TextStyle(
    fontSize: 14,
    color: grisTextoSecundario,
    fontWeight: FontWeight.w400,
  );

  // --- COMPONENTES PRE-DECORADOS (TUS "CLASES BOOTSTRAP") ---

  static BoxDecoration decoracionTarjeta = BoxDecoration(
    color: blancoPuro,
    borderRadius: BorderRadius.circular(radioTarjeta),
    border: Border.all(color: grisBordes.withOpacity(0.5)),
    boxShadow: sombraSuave,
  );
}
