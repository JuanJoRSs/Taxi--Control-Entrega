import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'theme/app_theme.dart'; 
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
// IMPORTANTE: Añadimos la importación de la pantalla de cambio de contraseña
import 'pages/cambio_password.dart'; 

final ValueNotifier<ThemeMode> themeNotifier = ValueNotifier(ThemeMode.light);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // CORRECCIÓN: Añadimos configuración para habilitar el flujo de autenticación por enlace
  await Supabase.initialize(
    url: 'https://bdczjlpwlzjjusjfxgxr.supabase.co',
    anonKey: 'sb_publishable_hLCkJFrTNxxHAx2g9S-VSQ_nKQi2TvT',
    authOptions: const FlutterAuthClientOptions(
      authFlowType: AuthFlowType.pkce, // Recomendado para mayor seguridad en móviles
    ),
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
          
          themeMode: currentMode,

          // TEMA CLARO
          theme: ThemeData.light().copyWith(
            scaffoldBackgroundColor: TaxiTheme.backgroundLight,
            appBarTheme: const AppBarTheme(
              backgroundColor: TaxiTheme.primaryDark,
              elevation: 0,
              iconTheme: IconThemeData(color: Colors.white),
              titleTextStyle: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ),

          // TEMA OSCURO
          darkTheme: ThemeData.dark().copyWith(
            scaffoldBackgroundColor: const Color(0xFF121212),
            appBarTheme: const AppBarTheme(
              backgroundColor: Color(0xFF1E1E1E),
              elevation: 0,
              iconTheme: IconThemeData(color: TaxiTheme.accentGold),
              titleTextStyle: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ),

          initialRoute: '/',

          routes: {
            '/': (context) => const LoginPage(),
            '/login': (context) => const LoginPage(),
            // NUEVA RUTA: Para que el sistema sepa a dónde ir al recuperar contraseña
            '/cambio-password': (context) => const PantallaCambioPassword(),
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