import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../theme/app_theme.dart'; // Importamos los colores y estilos personalizados

class PantallaCambioPassword extends StatefulWidget {
  const PantallaCambioPassword({super.key});

  @override
  State<PantallaCambioPassword> createState() => _PantallaCambioPasswordState();
}

class _PantallaCambioPasswordState extends State<PantallaCambioPassword> {
  final _controladorPassword = TextEditingController(); // Controlador para capturar lo que el usuario escribe en el campo de texto
  
  bool _cargando = false;
  bool _obscureText = true; // Variable para que el usuario decida si quiere ver lo que escribe o no en el campo de contraseña

  Future<void> _actualizarContrasena() async {   // Función principal para actualizar la contraseña del usuario en Supabase
    final nuevaPassword = _controladorPassword.text.trim(); 

    if (nuevaPassword.length < 6) { // Validación: La contraseña debe tener al menos 6 caracteres (requisito de Supabase)
      _mostrarMensaje('La contraseña debe tener al menos 6 caracteres', esError: true);
      return; // Si es muy corta, nos detenemos aquí y no enviamos nada
    }

    // Encendemos el estado de carga para bloquear el botón y que no lo pulsen dos veces
    setState(() { _cargando = true; });

    try {
      final supabase = Supabase.instance.client;
      final usuarioActual = supabase.auth.currentUser;

      if (usuarioActual != null) { //Actualizar la contraseña en el sistema de Autenticación de Supabase si se supera e
        await supabase.auth.updateUser(
          UserAttributes(password: nuevaPassword),
        );

        await supabase //Actualizar la tabla 'conductores' en la base de datos SQL
            .from('conductores')
            .update({'debe_cambiar_pass': false}) // Marcamos 'debe_cambiar_pass' como falso para que no le vuelva a pedir el cambio al entrar.
            .eq('auth_id', usuarioActual.id);

        _mostrarMensaje('Seguridad actualizada con éxito'); //Si no hay fallo se muestra mensaje de éxito

        if (mounted) {
          Navigator.pushReplacementNamed(context, '/menu'); //Vamos al menú, ya que se entiende que después de cambiar la contraseña el usuario querrá entrar a la aplicación
        }
      }
    } catch (e) {
      _mostrarMensaje('Error al sincronizar datos: $e', esError: true); //Si hay error se muestra el mensaje de que ha fallado
    } finally {
      if (mounted) setState(() { _cargando = false; }); // Apagamos el indicador de carga
    }
  }

  void _mostrarMensaje(String mensaje, {bool esError = false}) { //Función para pasar mensajes con un Booleano por parámetro que nos indica el color que se usa
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje),
        backgroundColor: esError ? TaxiTheme.error : Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) { // Construcción de la interfaz de usuario
    return Scaffold(
      backgroundColor: TaxiTheme.backgroundLight,
      appBar: AppBar(
        title: const Text('Seguridad de la Cuenta', style: TaxiTheme.tituloAppBar), //Título del AppBar
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
            decoration: TaxiTheme.decoracionTarjeta, //Parámetros de decoración de tarjeta del Token Theme
            padding: const EdgeInsets.all(32.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Icono decorativo de una llave en color dorado
                const Icon(
                  Icons.vpn_key_rounded, //Icono de la librería de material de Flutter
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
                  'Por seguridad, cambia la contraseña genérica por una personal para proteger tus datos de servicio.', //Un mensaje de explicaicon de por qué se ha redirigido al usuario a esta pantalla
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: TaxiTheme.textSecondary,
                    fontSize: 15,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 32),

                TextField( // Campo de entrada de contraseña
                  controller: _controladorPassword,
                  obscureText: _obscureText, // Oculta o muestra el texto
                  style: const TextStyle(color: TaxiTheme.textPrimary),
                  decoration: InputDecoration(
                    labelText: 'Nueva Contraseña',
                    prefixIcon: const Icon(Icons.lock_outline, color: TaxiTheme.primaryDark),
                    // Botón del "ojo" para ver u ocultar lo escrito
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureText ? Icons.visibility_off : Icons.visibility, // Cambia el icono según el estado de visibilidad que elija el usuario
                        color: TaxiTheme.textSecondary,
                      ),
                      onPressed: () => setState(() => _obscureText = !_obscureText), //Al pulsar el icono se cambia el estado de visibilidad de la contraseña
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
                    child: _cargando //Si _cargando es verdadero, se muestra un indicador de carga, si no, se muestra el texto del botón para confirmar y entrar a la aplicación
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