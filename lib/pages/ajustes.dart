import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../theme/app_theme.dart';

class AjustesPage extends StatefulWidget {
  const AjustesPage({super.key});

  @override
  State<AjustesPage> createState() => _AjustesPageState();
}

class _AjustesPageState extends State<AjustesPage> {
  final _supabase = Supabase.instance.client;
  bool _notificacionesActivas = true;

  // Lógica para cerrar sesión de forma segura
  Future<void> _cerrarSesion() async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        title: const Text('¿CERRAR SESIÓN?', style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text('Tendrás que volver a introducir tu correo y contraseña para entrar.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('CANCELAR', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('SALIR', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmar == true) {
      await _supabase.auth.signOut(); // Cierra sesión en la base de datos
      if (mounted) {
        // Destruye el historial de navegación y te manda al login
        Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Obtenemos los datos del usuario logueado
    final usuarioActual = _supabase.auth.currentUser;
    final correoUsuario = usuarioActual?.email ?? 'Usuario no identificado';

    // Variables de color que se adaptan automáticamente al modo oscuro
    final colorTarjeta = Theme.of(context).cardColor;
    final colorTexto = Theme.of(context).textTheme.bodyLarge?.color;

    return Scaffold(
      // TopBar corregida para que sea idéntica al resto de la app
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
          
          // --- SECCIÓN 1: PERFIL ---
          const Padding(
            padding: EdgeInsets.only(left: 8, bottom: 8),
            child: Text('MI CUENTA', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 12)),
          ),
          Container(
            decoration: BoxDecoration(
              color: colorTarjeta,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
            ),
            child: Column(
              children: [
                ListTile(
                  leading: CircleAvatar(
                    backgroundColor: TaxiTheme.accentGold.withOpacity(0.2),
                    child: const Icon(Icons.person, color: TaxiTheme.accentGold),
                  ),
                  title: Text('Conductor Activo', style: TextStyle(fontWeight: FontWeight.bold, color: colorTexto)),
                  subtitle: Text(correoUsuario, style: const TextStyle(color: Colors.grey)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // --- SECCIÓN 2: PREFERENCIAS ---
          const Padding(
            padding: EdgeInsets.only(left: 8, bottom: 8),
            child: Text('PREFERENCIAS', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 12)),
          ),
          Container(
            decoration: BoxDecoration(
              color: colorTarjeta,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
            ),
            child: Column(
              children: [
                SwitchListTile(
                  activeColor: TaxiTheme.accentGold,
                  secondary: const Icon(Icons.dark_mode_outlined),
                  title: Text('Modo Oscuro', style: TextStyle(color: colorTexto)),
                  // Conectamos el botón con el Cerebro Global
                  value: temaGlobal.value == ThemeMode.dark,
                  onChanged: (bool valor) {
                    setState(() {
                      temaGlobal.value = valor ? ThemeMode.dark : ThemeMode.light;
                    });
                  },
                ),
                const Divider(height: 1, indent: 70, endIndent: 16),
                SwitchListTile(
                  activeColor: TaxiTheme.accentGold,
                  secondary: const Icon(Icons.notifications_active_outlined),
                  title: Text('Notificaciones push', style: TextStyle(color: colorTexto)),
                  value: _notificacionesActivas,
                  onChanged: (bool valor) {
                    setState(() => _notificacionesActivas = valor);
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),

          // --- SECCIÓN 3: CERRAR SESIÓN ---
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).scaffoldBackgroundColor, 
              foregroundColor: Colors.red, 
              elevation: 0,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: const BorderSide(color: Colors.red, width: 1.5), 
              ),
            ),
            icon: const Icon(Icons.logout),
            label: const Text('CERRAR SESIÓN', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1)),
            onPressed: _cerrarSesion,
          ),
          
          const SizedBox(height: 24),
          const Center(
            child: Text('TaxiControl v1.0.0', style: TextStyle(color: Colors.grey, fontSize: 12)),
          ),
        ],
      ),
    );
  }
}