//Imports
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../theme/app_theme.dart';
import 'cambio_password.dart'; 

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  // Controladores para capturar el texto que el usuario escriba
  final TextEditingController _userController = TextEditingController();
  final TextEditingController _passController = TextEditingController();
  
  // Variable para controlar si mostramos la animación de carga en el botón
  bool _cargando = false;
  
  // Instanciamos el cliente de Supabase
  final supabase = Supabase.instance.client;

  @override
  void initState() {
    super.initState();
    // ESCUCHADOR DE ENLACES: Detecta si el usuario vuelve a la app desde el correo
    _escucharRetornoDeEmail();
  }

  /// Detecta si el usuario ha pulsado el enlace de recuperación en su correo
  void _escucharRetornoDeEmail() {
    supabase.auth.onAuthStateChange.listen((data) {
      final AuthChangeEvent event = data.event;
      // Si el evento es 'passwordRecovery', navegamos directamente a la pantalla de cambio
      if (event == AuthChangeEvent.passwordRecovery) {
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const PantallaCambioPassword()),
          );
        }
      }
    });
  }

  /// FUNCIÓN: Recuperación de contraseña con servidor SMTP profesional
  Future<void> _enviarCorreoRecuperacion() async {
    final email = _userController.text.trim();

    if (email.isEmpty) {
      _mostrarMensaje('Por favor, escribe tu email para enviarte el enlace', esError: true);
      return;
    }

    setState(() { _cargando = true; });

    try {
      // Enviamos el correo. Supabase usará automáticamente tu SMTP de Resend configurado.
      await supabase.auth.resetPasswordForEmail(
        email,
        // IMPORTANTE: Este redirectTo debe coincidir con tu AndroidManifest y Supabase Dashboard
        redirectTo: 'io.supabase.flutter://reset-callback/', 
      );

      _mostrarMensaje('¡Correo enviado! Revisa tu bandeja de entrada (y spam).');

    } catch (e) {
      _mostrarMensaje('No se pudo enviar el correo de recuperación', esError: true);
    } finally {
      if (mounted) setState(() { _cargando = false; });
    }
  }

  /// Función asíncrona para gestionar el inicio de sesión normal
  Future<void> login() async {
    setState(() { _cargando = true; });

    try {
      final response = await supabase.auth.signInWithPassword(
        email: _userController.text.trim(), 
        password: _passController.text.trim(),
      );

      final usuarioActual = response.user;

      if (!mounted) return;

      if (usuarioActual != null) {
        // Verificamos si es su primera vez en la tabla 'conductores'
        final datosConductor = await supabase
            .from('conductores')
            .select('debe_cambiar_pass')
            .eq('auth_id', usuarioActual.id)
            .single();

        final debeCambiar = datosConductor['debe_cambiar_pass'] ?? false;

        if (!mounted) return;

        if (debeCambiar == true) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const PantallaCambioPassword()),
          );
        } else {
          Navigator.pushReplacementNamed(context, '/menu');
          _mostrarMensaje('Acceso concedido');
        }
      }
    } on AuthException {
      _mostrarMensaje('Error: Revise sus credenciales', esError: true);
    } catch (e) {
      _mostrarMensaje('Error inesperado al conectar', esError: true);
    } finally {
      if (mounted) setState(() { _cargando = false; });
    }
  }

  // Helper para SnackBars
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
        title: const Text('ACCESO AL SISTEMA', style: TaxiTheme.tituloAppBar),
        centerTitle: true,
        backgroundColor: TaxiTheme.primaryDark,
        elevation: 0,
        automaticallyImplyLeading: false, 
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 30),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Logo
                Container(
                  height: 140,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.15),
                        blurRadius: 25,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Image.asset('assets/images/logo.png'), 
                ),
                const SizedBox(height: 15),
                const Text(
                  'TAXI CONTROL',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 3,
                    color: TaxiTheme.primaryDark,
                  ),
                ),
                
                const SizedBox(height: 40),

                // Tarjeta de Login
                Container(
                  padding: const EdgeInsets.all(25),
                  decoration: TaxiTheme.decoracionTarjeta.copyWith(
                    color: TaxiTheme.surfaceWhite, 
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08), 
                        blurRadius: 15,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      TextField(
                        controller: _userController,
                        style: const TextStyle(color: TaxiTheme.textPrimary),
                        textInputAction: TextInputAction.next,
                        decoration: InputDecoration(
                          labelText: 'Email del Conductor',
                          labelStyle: const TextStyle(color: TaxiTheme.textSecondary),
                          prefixIcon: const Icon(Icons.email_outlined, color: TaxiTheme.primaryDark),
                          filled: true,
                          fillColor: TaxiTheme.backgroundLight.withOpacity(0.3), 
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      TextField(
                        controller: _passController,
                        obscureText: true,
                        style: const TextStyle(color: TaxiTheme.textPrimary),
                        textInputAction: TextInputAction.done,
                        onSubmitted: (value) => login(),
                        decoration: InputDecoration(
                          labelText: 'Contraseña',
                          labelStyle: const TextStyle(color: TaxiTheme.textSecondary),
                          prefixIcon: const Icon(Icons.lock_person_outlined, color: TaxiTheme.primaryDark),
                          filled: true,
                          fillColor: TaxiTheme.backgroundLight.withOpacity(0.3), 
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                      
                      // Botón Olvidé mi contraseña
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: _cargando ? null : _enviarCorreoRecuperacion,
                          child: const Text(
                            'Olvidé mi contraseña',
                            style: TextStyle(
                              color: TaxiTheme.accentGold,
                              fontWeight: FontWeight.bold,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 30),

                // Botón Acceder
                SizedBox(
                  width: double.infinity,
                  height: 60,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: TaxiTheme.primaryDark,
                      foregroundColor: TaxiTheme.surfaceWhite,
                      elevation: 8,
                      shadowColor: TaxiTheme.primaryDark.withOpacity(0.5),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                    ),
                    onPressed: _cargando ? null : login, 
                    child: _cargando 
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text(
                            'ACCEDER A MI CUENTA',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.8,
                            ),
                          ),
                  ),
                ),
                
                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
    );
  }
}