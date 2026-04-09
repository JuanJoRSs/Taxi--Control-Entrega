import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../theme/app_theme.dart'; 

class PantallaCambioPassword extends StatefulWidget {
  const PantallaCambioPassword({Key? key}) : super(key: key);

  @override
  State<PantallaCambioPassword> createState() => _PantallaCambioPasswordState();
}

class _PantallaCambioPasswordState extends State<PantallaCambioPassword> {
  // Controlador para capturar lo que el usuario escribe
  final _controladorPassword = TextEditingController();
  
  // Estados para la interfaz
  bool _cargando = false;
  bool _obscureText = true;

  /// Función principal para actualizar la seguridad del usuario
  Future<void> _actualizarContrasena() async {
    final nuevaPassword = _controladorPassword.text.trim();

    // Validamos que la contraseña sea segura (mínimo 6 caracteres por norma de Supabase)
    if (nuevaPassword.length < 6) {
      _mostrarMensaje('La contraseña debe tener al menos 6 caracteres', esError: true);
      return;
    }

    setState(() { _cargando = true; });

    try {
      final supabase = Supabase.instance.client;
      final usuarioActual = supabase.auth.currentUser;

      if (usuarioActual != null) {
        // PASO 1: Actualizar la contraseña en el sistema de Autenticación
        // Esto cambia la clave con la que el usuario hace login.
        await supabase.auth.updateUser(
          UserAttributes(password: nuevaPassword),
        );

        // PASO 2: Actualizar nuestra tabla de base de datos 'conductores'
        // Marcamos 'debe_cambiar_pass' como falso para que no le vuelva a pedir el cambio.
        // Usamos 'auth_id' para encontrar al conductor exacto.
        await supabase
            .from('conductores')
            .update({'debe_cambiar_pass': false})
            .eq('auth_id', usuarioActual.id);

        _mostrarMensaje('Seguridad actualizada con éxito');

        // PASO 3: Navegación
        // Si todo salió bien, lo mandamos al menú principal
        if (mounted) {
          Navigator.pushReplacementNamed(context, '/menu');
        }
      }
    } catch (e) {
      _mostrarMensaje('Error al sincronizar datos: $e', esError: true);
    } finally {
      if (mounted) setState(() { _cargando = false; });
    }
  }

  // Función auxiliar para mostrar notificaciones (SnackBars)
  void _mostrarMensaje(String mensaje, {bool esError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje),
        backgroundColor: esError ? TaxiTheme.error : Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TaxiTheme.backgroundLight,
      appBar: AppBar(
        title: const Text('Seguridad de la Cuenta', style: TaxiTheme.tituloAppBar),
        backgroundColor: TaxiTheme.primaryDark,
        elevation: 0,
        automaticallyImplyLeading: false, // Evita que vuelvan atrás sin cambiar la pass
        centerTitle: true,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Container(
            decoration: TaxiTheme.decoracionTarjeta,
            padding: const EdgeInsets.all(32.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.vpn_key_rounded,
                  size: 64,
                  color: TaxiTheme.accentGold,
                ),
                const SizedBox(height: 24),
                const Text(
                  'Actualización Obligatoria',
                  style: TextStyle(
                    color: TaxiTheme.textPrimary,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Por seguridad, cambia la contraseña genérica por una personal para proteger tus datos de servicio.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: TaxiTheme.textSecondary,
                    fontSize: 15,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 32),
                
                // Campo de entrada de contraseña
                TextField(
                  controller: _controladorPassword,
                  obscureText: _obscureText,
                  style: const TextStyle(color: TaxiTheme.textPrimary),
                  decoration: InputDecoration(
                    labelText: 'Nueva Contraseña',
                    labelStyle: const TextStyle(color: TaxiTheme.textSecondary),
                    prefixIcon: const Icon(Icons.lock_outline, color: TaxiTheme.primaryDark),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureText ? Icons.visibility_off : Icons.visibility,
                        color: TaxiTheme.textSecondary,
                      ),
                      onPressed: () => setState(() => _obscureText = !_obscureText),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Colors.grey, width: 0.5),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: TaxiTheme.accentGold, width: 2),
                    ),
                    filled: true,
                    fillColor: Colors.grey.withOpacity(0.05),
                  ),
                ),
                const SizedBox(height: 32),
                
                // Botón de confirmación
                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton(
                    onPressed: _cargando ? null : _actualizarContrasena,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: TaxiTheme.primaryDark,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      elevation: 2,
                    ),
                    child: _cargando
                        ? const CircularProgressIndicator(color: TaxiTheme.accentGold)
                        : const Text(
                            'CONFIRMAR Y ENTRAR',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.2,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}