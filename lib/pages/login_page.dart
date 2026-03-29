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

  // Función asíncrona para gestionar el inicio de sesión
  Future<void> login() async {
    // Encendemos la animación de carga
    setState(() {
      _cargando = true;
    });

    try {
      // PASO 1: Intentamos iniciar sesión con email y contraseña
      final response = await supabase.auth.signInWithPassword(
        email: _userController.text.trim(), 
        password: _passController.text.trim(),
      );

      final usuarioActual = response.user;

      // Verificamos si el widget sigue en pantalla
      if (!mounted) return;

      // Si Supabase nos devuelve un usuario válido, el login ha sido exitoso
      if (usuarioActual != null) {
        
        // PASO 2: Consultamos a la tabla 'conductores' si necesita cambiar la clave
        final datosConductor = await supabase
            .from('conductores')
            .select('debe_cambiar_pass')
            .eq('auth_id', usuarioActual.id)
            .single();

        // Guardamos el valor (si es nulo por algún motivo, asumimos que no hace falta)
        final debeCambiar = datosConductor['debe_cambiar_pass'] ?? false;

        if (!mounted) return;

        // PASO 3: Decidimos a qué pantalla enviarlo
        if (debeCambiar == true) {
          // Es su primera vez: Lo enviamos a cambiar la contraseña obligatoriamente
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const PantallaCambioPassword()),
          );
        } else {
          // Ya tiene su clave personal: Lo enviamos al menú principal
          Navigator.pushReplacementNamed(context, '/menu');

          // Mostramos un mensaje de éxito
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
        SnackBar(
          content: Text('Error: Revise sus credenciales'), // Mensaje más amigable
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
      // Apagamos la animación de carga ocurra lo que ocurra
      if (mounted) {
        setState(() {
          _cargando = false;
        });
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
        automaticallyImplyLeading: false, //Este param sirve para eliminar la flecha de volver hacia atras en el historial
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 30),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
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
                        //Le dice al teclado que el siguiente paso es pasar al otro campo
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
                        //Le dice al teclado que este es el último campo
                        textInputAction: TextInputAction.done,
                        //Detecta cuando se pulsa el botón de Enter y lanza la función de login
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
                    ],
                  ),
                ),

                const SizedBox(height: 40),

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
                    // Si _cargando es true, deshabilitamos el botón (pasando null)
                    onPressed: _cargando ? null : login, 
                    // Si _cargando es true, mostramos la rueda; si no, el texto normal
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