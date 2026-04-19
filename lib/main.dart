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
import 'pages/cambio_password.dart';

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
    // Envolvemos la app para que escuche el cambio de modo
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: temaGlobal,
      builder: (context, modoActual, child) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'TaxiControl',
          
          // Propiedades añadidas para gestionar el tema
          theme: TaxiTheme.temaClaro,
          darkTheme: TaxiTheme.temaOscuro,
          themeMode: modoActual,

          //Mantenemos '/' como login por consistencia
          initialRoute: '/',

          routes: {
            //RUTA DE ACCESO
            '/': (context) => const LoginPage(),
            '/login': (context) => const LoginPage(),
            // NUEVA RUTA: Para que el sistema sepa a dónde ir al recuperar contraseña
            '/cambio-password': (context) => const PantallaCambioPassword(),
            //MENÚ PRINCIPAL (GRID 3x4)
            '/menu': (context) => const MenuPrincipal(),

            //PÁGINAS OPERATIVAS
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
      }
    );
  }
}
