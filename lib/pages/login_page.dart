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
  
  // Instanciamos el cliente de Supabase para realizar las peticiones al servidor
  final supabase = Supabase.instance.client;

  // --- NUEVA FUNCIÓN: Recuperación de contraseña ---
  Future<void> _enviarCorreoRecuperacion() async {
    final email = _userController.text.trim();

    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor, escribe tu email para enviarte el enlace'),
          backgroundColor: TaxiTheme.error,
        ),
      );
      return;
    }

    setState(() { _cargando = true; });

    try {
      // Supabase envía el correo automáticamente
      await supabase.auth.resetPasswordForEmail(
        email,
        redirectTo: 'io.supabase.flutter://reset-callback/', 
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('¡Correo de recuperación enviado! Revisa tu bandeja.'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No se pudo enviar el correo de recuperación'),
            backgroundColor: TaxiTheme.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() { _cargando = false; });
    }
  }

  // Función asíncrona para gestionar el inicio de sesión (Mantenemos tu lógica original)
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
        // Consultamos si necesita cambiar la clave
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
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Acceso concedido'),
              backgroundColor: TaxiTheme.success, 
            ),
          );
        }
      }
    } on AuthException {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error: Revise sus credenciales'),
          backgroundColor: TaxiTheme.error, 
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error inesperado al conectar'),
          backgroundColor: TaxiTheme.error,
        ),
      );
    } finally {
      if (mounted) {
        setState(() { _cargando = false; });
      }
    }
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
                      // Campo Email
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
                      // Campo Password
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
                      
                      // --- NUEVO: Botón Olvidé mi contraseña ---
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