import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
// Asegúrate de que el import de tu TaxiTheme sea correcto según tu estructura de archivos
import '../theme/app_theme.dart'; 

class PantallaCambioPassword extends StatefulWidget {
  const PantallaCambioPassword({Key? key}) : super(key: key);

  @override
  State<PantallaCambioPassword> createState() => _PantallaCambioPasswordState();
}

class _PantallaCambioPasswordState extends State<PantallaCambioPassword> {
  final _controladorPassword = TextEditingController();
  bool _cargando = false;
  bool _obscureText = true;

  Future<void> _actualizarContrasena() async {
    final nuevaPassword = _controladorPassword.text;

    if (nuevaPassword.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('La contraseña debe tener al menos 6 caracteres'),
          backgroundColor: TaxiTheme.error,
        ),
      );
      return;
    }

    setState(() { _cargando = true; });

    try {
      final supabase = Supabase.instance.client;
      final usuarioActual = supabase.auth.currentUser;

      if (usuarioActual != null) {
        await supabase.auth.updateUser(
          UserAttributes(password: nuevaPassword),
        );

        await supabase
            .from('conductores')
            .update({'debe_cambiar_pass': false})
            .eq('auth_id', usuarioActual.id);

        if (mounted) {
          Navigator.pushReplacementNamed(context, '/menu');
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cambiar la contraseña: $e'),
            backgroundColor: TaxiTheme.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() { _cargando = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TaxiTheme.backgroundLight,
      appBar: AppBar(
        title: const Text('Seguridad de la Cuenta', style: TaxiTheme.tituloAppBar),
        backgroundColor: TaxiTheme.primaryDark,
        elevation: 0,
        automaticallyImplyLeading: false,
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
                // Icono decorativo en dorado
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
                
                // Campo de texto estilizado
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
                
                // Botón principal
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