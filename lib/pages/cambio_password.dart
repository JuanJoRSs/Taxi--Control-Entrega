import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../theme/app_theme.dart'; // Importamos los colores y estilos personalizados

class PantallaCambioPassword extends StatefulWidget {
  const PantallaCambioPassword({super.key});

  @override
  State<PantallaCambioPassword> createState() => _PantallaCambioPasswordState();
}

class _PantallaCambioPasswordState extends State<PantallaCambioPassword> {
  //  Guardamos lo que pasa en la pantalla mientras el usuario la usa
  
  // Este controlador es como un "imán" que atrapa el texto que el usuario escribe
  final _controladorPassword = TextEditingController();
  
  // Si esto es true, mostramos un círculo de carga en el botón
  bool _cargando = false; 
  
  // Si esto es true, la contraseña se ve como asteriscos a modo de censura 
  bool _obscureText = true;

  ///  La función que actualiza la contraseña al darle al boton     
  Future<void> _actualizarContrasena() async {
    // Quitamos los espacios vacíos al principio y al final de lo que escribió el usuario
    final nuevaPassword = _controladorPassword.text.trim();

    // Condicional ya que Supabase no acepta contraseñas de menos de 6 letras por seguridad
    if (nuevaPassword.length < 6) {
      _mostrarMensaje('La contraseña debe tener al menos 6 caracteres', esError: true);
      return; // Si es muy corta, nos detenemos aquí y no enviamos nada
    }

    // Encendemos el estado de carga para bloquear el botón y que no lo pulsen dos veces
    setState(() { _cargando = true; });

    try {
      final supabase = Supabase.instance.client;
      final usuarioActual = supabase.auth.currentUser;

      if (usuarioActual != null) {
        //  Cambiamos la key de acceso en el sistema de Autenticación 
        await supabase.auth.updateUser(
          UserAttributes(password: nuevaPassword),
        );

        //  Actualizamos nuestra tabla de SQL 'conductores'
        // Cambiamos el valor 'debe_cambiar_pass' a falso para que el sistema
        // sepa que este usuario ya cumplió con el requisito de seguridad.
        await supabase
            .from('conductores')
            .update({'debe_cambiar_pass': false})
            .eq('auth_id', usuarioActual.id); // Solo cambiamos al usuario que está logueado

        _mostrarMensaje('Seguridad actualizada con éxito');

        //  Mandamos al usuario al menú principal 
        // Usamos pushReplacement para que no pueda darle al botón "atrás" del móvil y volver aquí
        if (mounted) {
          Navigator.pushReplacementNamed(context, '/menu');
        }
      }
    } catch (e) {
      // Si algo falla (ejemplo: no hay internet), mostramos el error
      _mostrarMensaje('Error al sincronizar datos: $e', esError: true);
    } finally {
      // Pase lo que pase, apagamos el circulito de carga al terminar
      if (mounted) setState(() { _cargando = false; });
    }
  }

  // Función rápida para sacar un cartelito (SnackBar) en la parte de abajo de la pantalla
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
        //  Quitamos la flecha de atrás para obligar al usuario a cambiar la clave
        automaticallyImplyLeading: false, 
        centerTitle: true,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Container(
            // Aplicamos el diseño de tarjeta
            decoration: TaxiTheme.decoracionTarjeta,
            padding: const EdgeInsets.all(32.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Icono decorativo de una llave en color dorado
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
                
                // Campo de texto para la contraseña
                TextField(
                  controller: _controladorPassword,
                  obscureText: _obscureText, // Oculta o muestra el texto
                  style: const TextStyle(color: TaxiTheme.textPrimary),
                  decoration: InputDecoration(
                    labelText: 'Nueva Contraseña',
                    prefixIcon: const Icon(Icons.lock_outline, color: TaxiTheme.primaryDark),
                    // Botón del "ojo" para ver u ocultar lo escrito
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
                  ),
                ),
                const SizedBox(height: 32),
                
                // Boton de confirmacion 
                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton(
                    // Si está cargando, desactivamos el botón (null)
                    onPressed: _cargando ? null : _actualizarContrasena,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: TaxiTheme.primaryDark,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
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