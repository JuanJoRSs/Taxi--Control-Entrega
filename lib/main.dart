import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'theme/app_theme.dart'; // <--- IMPORTANTE PARA LEER TUS COLORES GLOBALES
import 'pages/login_page.dart';
import 'pages/fichaje.dart'; 
import 'pages/menu.dart';
import 'pages/gestion_plantilla.dart';
import 'pages/activo.dart'; 
import 'pages/export.dart';
import 'pages/historial.dart'; 
import 'pages/trafico.dart';
import 'pages/notas_coche.dart';
import 'pages/facturacion.dart';
import 'pages/estaciones.dart';
import 'pages/agenda.dart';
import 'pages/ajustes.dart';
import 'pages/agencia.dart';

// VARIABLE GLOBAL: Controla el tema desde cualquier parte de la app.
final ValueNotifier<ThemeMode> themeNotifier = ValueNotifier(ThemeMode.light);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://bdczjlpwlzjjusjfxgxr.supabase.co',
    anonKey: 'sb_publishable_hLCkJFrTNxxHAx2g9S-VSQ_nKQi2TvT',
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeNotifier,
      builder: (_, currentMode, __) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'TaxiControl',
          
          // Le decimos a Flutter que escuche al interruptor
          themeMode: currentMode,

          // 1. TEMA CLARO OFICIAL (Tus colores corporativos)
          theme: ThemeData.light().copyWith(
            scaffoldBackgroundColor: TaxiTheme.backgroundLight,
            appBarTheme: const AppBarTheme(
              backgroundColor: TaxiTheme.primaryDark,
              elevation: 0,
              iconTheme: IconThemeData(color: Colors.white),
              titleTextStyle: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ),

          // 2. TEMA OSCURO OFICIAL (Colores de alto contraste)
          darkTheme: ThemeData.dark().copyWith(
            scaffoldBackgroundColor: const Color(0xFF121212), // Fondo gris muy oscuro
            appBarTheme: const AppBarTheme(
              backgroundColor: Color(0xFF1E1E1E), // Barra superior oscura
              elevation: 0,
              iconTheme: IconThemeData(color: TaxiTheme.accentGold), // Iconos dorados para que destaquen
              titleTextStyle: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ),

          initialRoute: '/',

          routes: {
            '/': (context) => const LoginPage(),
            '/login': (context) => const LoginPage(),
            '/menu': (context) => const MenuPrincipal(),
            '/fichaje': (context) => const Fichaje(),
            '/activos': (context) => const Activo(), 
            '/gestion-plantilla': (context) => const GestionPlantilla(), 
            '/export': (context) => const Export(),
            '/trafico': (context) => const TraficoPage(),
            '/historial': (context) => const HistorialPage(), 
            '/notas-coche': (context) => const NotasCoche(),
            '/facturacion': (context) => const Facturacion(),
            '/estaciones': (context) => const EstacionesPage(),
            '/agenda': (context) => const AgendaContactos(),
            '/ajustes': (context) => const AjustesPage(),
            '/agencias': (context) => const Agencias()
          },
        );
      },
    );
  }
}
