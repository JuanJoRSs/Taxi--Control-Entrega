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

  /// FUNCIÓN: Gestión del inicio de sesión normal
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
        // Verificamos en la tabla SQL si es su primera vez y debe cambiar la clave genérica
        final datosConductor = await supabase
            .from('conductores')
            .select('debe_cambiar_pass')
            .eq('auth_id', usuarioActual.id)
            .single();

        final debeCambiar = datosConductor['debe_cambiar_pass'] ?? false;

        if (!mounted) return;

        // Si es la primera vez, le mandamos a la pantalla de cambio obligatorio
        if (debeCambiar == true) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const PantallaCambioPassword()),
          );
        } else {
          // Si ya la cambió antes, entra directo al menú
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

  // Función auxiliar para mostrar mensajes (SnackBars)
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
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
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
                // Logo de Taxi Control
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
                Text(
                  'TAXI CONTROL',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 3,
                    color: Theme.of(context).textTheme.bodyLarge?.color,
                  ),
                ),
                
                const SizedBox(height: 40),

                // Tarjeta de Login (Email y Password)
                Container(
                  padding: const EdgeInsets.all(25),
                  decoration: TaxiTheme.decoracionTarjeta.copyWith(
                    color: Theme.of(context).cardColor,
                  ),
                  child: Column(
                    children: [
                      TextField(
                        controller: _userController,
                        style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color),
                        textInputAction: TextInputAction.next,
                        decoration: InputDecoration(
                          labelText: 'Email del Conductor',
                          labelStyle: const TextStyle(color: TaxiTheme.textSecondary),
                          prefixIcon: Icon(Icons.email_outlined, color: Theme.of(context).colorScheme.secondary),
                          filled: true,
                          fillColor: Theme.of(context).scaffoldBackgroundColor.withOpacity(0.3),
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
                        style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color),
                        textInputAction: TextInputAction.done,
                        onSubmitted: (value) => login(),
                        decoration: InputDecoration(
                          labelText: 'Contraseña',
                          labelStyle: const TextStyle(color: TaxiTheme.textSecondary),
                          prefixIcon: Icon(Icons.lock_person_outlined, color: Theme.of(context).colorScheme.secondary),
                          filled: true,
                          fillColor: Theme.of(context).scaffoldBackgroundColor.withOpacity(0.3), 
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide.none,
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