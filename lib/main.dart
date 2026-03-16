import 'package:flutter/material.dart';
import 'package:myapp/pages/notas_coche.dart';
import 'package:myapp/pages/trafico.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:myapp/pages/login_page.dart';
import 'pages/fichaje.dart'; 
import 'pages/menu.dart';
import 'pages/gestion_plantilla.dart';
import 'pages/activo.dart'; 
import 'pages/export.dart';
import 'pages/historial.dart'; 
import 'pages/facturacion.dart';
import 'pages/estaciones.dart';

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
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'TaxiControl',
      //Mantenemos '/' como login por consistencia
      initialRoute: '/',

      routes: {
        //RUTA DE ACCESO
        '/': (context) => const LoginPage(),

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
        '/estaciones': (context) => const EstacionesPage()
      },
    );
  }
}