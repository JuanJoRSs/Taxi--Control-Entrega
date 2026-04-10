//Imports
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../theme/app_theme.dart';
import '../main.dart'; // IMPORTANTE: Importamos main.dart para poder acceder a themeNotifier

class AjustesPage extends StatefulWidget {
  const AjustesPage({super.key});

  @override
  State<AjustesPage> createState() => _AjustesPageState();
}

class _AjustesPageState extends State<AjustesPage> {
  final _supabase = Supabase.instance.client;
  
  bool _notificacionesActivas = true;
  // Leemos el valor global actual para saber cómo debe empezar el interruptor
  late bool _modoOscuro; 

  @override
  void initState() {
    super.initState();
    // Si el tema global es dark, el interruptor empieza activado
    _modoOscuro = themeNotifier.value == ThemeMode.dark; 
  }

  // --- SOLUCIÓN AL CIERRE DE SESIÓN ---
  Future<void> _cerrarSesion() async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: TaxiTheme.surfaceWhite,
        title: const Text('¿CERRAR SESIÓN?', style: TextStyle(color: TaxiTheme.primaryDark, fontWeight: FontWeight.bold)),
        content: const Text('Tendrás que volver a introducir tu correo y contraseña para entrar.', style: TextStyle(color: TaxiTheme.textPrimary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('CANCELAR', style: TextStyle(color: TaxiTheme.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: TaxiTheme.error),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('SALIR', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmar == true) {
      try {
        // Forzamos el cierre en Supabase
        await _supabase.auth.signOut();
        
        if (mounted) {
          // Destruimos el historial y volvemos a la ruta exacta '/login'
          Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
        }
      } catch (e) {
        // Si Supabase falla por algo de red, avisamos pero echamos al usuario igualmente por seguridad
        debugPrint('Aviso al cerrar sesión en servidor: $e');
        if (mounted) {
           Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final usuarioActual = _supabase.auth.currentUser;
    final correoUsuario = usuarioActual?.email ?? 'Usuario no identificado';

    // Usamos Theme.of(context) para adaptar el fondo principal según el modo
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorFondo = isDark ? Colors.grey[900] : TaxiTheme.backgroundLight;
    final colorTexto = isDark ? Colors.white : TaxiTheme.textPrimary;
    final colorTarjeta = isDark ? Colors.grey[850] : TaxiTheme.surfaceWhite;

    return Scaffold(
      backgroundColor: colorFondo,
      appBar: AppBar(
        title: const Text('AJUSTES', style: TaxiTheme.tituloAppBar),
        centerTitle: true,
        backgroundColor: TaxiTheme.primaryDark,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          const Padding(
            padding: EdgeInsets.only(left: 8, bottom: 8),
            child: Text('MI CUENTA', style: TextStyle(color: TaxiTheme.textSecondary, fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 1.2)),
          ),
          Container(
            decoration: BoxDecoration(
              color: colorTarjeta,
              borderRadius: BorderRadius.circular(TaxiTheme.radioTarjeta),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
            ),
            child: Column(
              children: [
                ListTile(
                  leading: CircleAvatar(
                    backgroundColor: TaxiTheme.primaryDark.withOpacity(0.1),
                    child: const Icon(Icons.person, color: TaxiTheme.primaryDark),
                  ),
                  title: Text('Conductor Activo', style: TextStyle(fontWeight: FontWeight.bold, color: colorTexto)),
                  subtitle: Text(correoUsuario, style: const TextStyle(color: TaxiTheme.textSecondary)),
                ),
                const Divider(height: 1, indent: 70, endIndent: 16),
                ListTile(
                  leading: const Icon(Icons.lock_outline, color: TaxiTheme.primaryDark),
                  title: Text('Cambiar contraseña', style: TextStyle(color: colorTexto)),
                  trailing: const Icon(Icons.chevron_right, color: TaxiTheme.textSecondary),
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Función en desarrollo'), backgroundColor: TaxiTheme.primaryDark)
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          const Padding(
            padding: EdgeInsets.only(left: 8, bottom: 8),
            child: Text('PREFERENCIAS', style: TextStyle(color: TaxiTheme.textSecondary, fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 1.2)),
          ),
          Container(
            decoration: BoxDecoration(
              color: colorTarjeta,
              borderRadius: BorderRadius.circular(TaxiTheme.radioTarjeta),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
            ),
            child: Column(
              children: [
                SwitchListTile(
                  activeColor: TaxiTheme.accentGold,
                  secondary: const Icon(Icons.notifications_active_outlined, color: TaxiTheme.primaryDark),
                  title: Text('Notificaciones push', style: TextStyle(color: colorTexto)),
                  subtitle: const Text('Avisos de la central', style: TextStyle(color: TaxiTheme.textSecondary, fontSize: 12)),
                  value: _notificacionesActivas,
                  onChanged: (bool valor) {
                    setState(() => _notificacionesActivas = valor);
                  },
                ),
                const Divider(height: 1, indent: 70, endIndent: 16),
                
                // --- SOLUCIÓN AL MODO OSCURO ---
                SwitchListTile(
                  activeColor: TaxiTheme.accentGold,
                  secondary: const Icon(Icons.dark_mode_outlined, color: TaxiTheme.primaryDark),
                  title: Text('Modo Oscuro', style: TextStyle(color: colorTexto)),
                  value: _modoOscuro,
                  onChanged: (bool valor) {
                    setState(() => _modoOscuro = valor);
                    // Avisamos a la app entera de que debe cambiar
                    themeNotifier.value = valor ? ThemeMode.dark : ThemeMode.light;
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),

          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: colorTarjeta,
              foregroundColor: TaxiTheme.error,
              elevation: 0,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(TaxiTheme.radioTarjeta),
                side: const BorderSide(color: TaxiTheme.error, width: 1.5),
              ),
            ),
            icon: const Icon(Icons.logout),
            label: const Text('CERRAR SESIÓN', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1)),
            onPressed: _cerrarSesion,
          ),
          const SizedBox(height: 24),
          const Center(
            child: Text(
              'TaxiControl v1.0.0', 
              textAlign: TextAlign.center,
              style: TextStyle(color: TaxiTheme.textSecondary, fontSize: 12, height: 1.5),
            ),
          ),
        ],
      ),
    );
  }
}