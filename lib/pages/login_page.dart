//Imports
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../theme/app_theme.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  //Controladores para capturar el texto que el usuario escriba
  final TextEditingController _userController = TextEditingController();
  final TextEditingController _passController = TextEditingController();
  
  //Instanciamos el cliente de Supabase para realizar las peticiones al servidor
  final supabase = Supabase.instance.client;

  //Función asíncrona para gestionar el inicio de sesión
  Future<void> login() async {
    try {
      //Intentamos iniciar sesión con email y contraseña usando la API de Supabase
      final response = await supabase.auth.signInWithPassword(
        email: _userController.text.trim(), //trim() elimina espacios accidentales al inicio/final
        password: _passController.text.trim(),
      );

      //Verificamos si el widget sigue en pantalla antes de realizar acciones de contexto
      if (!mounted) return;

      //Si Supabase nos devuelve un usuario válido, el login ha sido exitoso
      if (response.user != null) {
        //Navegamos al menú principal eliminando la pantalla de login del historial
        Navigator.pushReplacementNamed(context, '/menu');

        //Mostramos un mensaje de éxito en la parte inferior
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Acceso concedido'),
            backgroundColor: TaxiTheme.success, 
          ),
        );
      }
    } on AuthException catch (e) {
      //Capturamos errores de autenticación 
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.message}'),
          backgroundColor: TaxiTheme.error, 
        ),
      );
    } catch (e) {
      //Capturamos cualquier otro error inesperado 
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error inesperado'),
          backgroundColor: TaxiTheme.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      //Definimos el color de fondo de la aplicación usando el token del tema.
      backgroundColor: TaxiTheme.backgroundLight,
      appBar: AppBar(
        title: const Text('ACCESO AL SISTEMA', style: TaxiTheme.tituloAppBar),
        centerTitle: true, // Centramos el título
        backgroundColor: TaxiTheme.primaryDark,
        elevation: 0, //Quitamos la sombra 
      ),
      body: Center(
        // SingleChildScrollView evita errores de "pixel overflow".
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 30),
            child: Column(
              mainAxisSize: MainAxisSize.min, //La columna solo ocupa el espacio necesario
              children: [
                //Contenedor decorativo para el logo circular
                Container(
                  height: 140,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      //Sombra para dar profundidad al logo
                      BoxShadow(
                        color: Colors.black.withOpacity(0.15),
                        blurRadius: 25,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  //Logo
                  child: Image.asset('assets/images/logo.png'), 
                ),
                const SizedBox(height: 15), //Espaciador vertical
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

                // Caja blanca que contiene los campos de entrada
                Container(
                  padding: const EdgeInsets.all(25),
                  // Usamos copyWith para asegurar que la sombra no sea negra sólida sino suave (withOpacity)
                  decoration: TaxiTheme.decoracionTarjeta.copyWith(
                    color: TaxiTheme.surfaceWhite, // Forzamos el blanco puro para que resalte
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08), // Sombra suave como en el menú
                        blurRadius: 15,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      //Campo de texto para el correo electrónico
                      TextField(
                        controller: _userController,
                        style: const TextStyle(color: TaxiTheme.textPrimary),
                        decoration: InputDecoration(
                          labelText: 'Email del Conductor',
                          labelStyle: const TextStyle(color: TaxiTheme.textSecondary),
                          prefixIcon: const Icon(Icons.email_outlined, color: TaxiTheme.primaryDark),
                          filled: true,
                          // Bajamos la opacidad del fondo del campo para que la tarjeta blanca mande
                          fillColor: TaxiTheme.backgroundLight.withOpacity(0.3), 
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      //Campo de texto oculto para la contraseña
                      TextField(
                        controller: _passController,
                        obscureText: true, //Oculta los caracteres
                        style: const TextStyle(color: TaxiTheme.textPrimary),
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

                //Botón principal de acceso
                SizedBox(
                  width: double.infinity, //El botón ocupa todo el ancho posible
                  height: 60,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: TaxiTheme.primaryDark,
                      foregroundColor: TaxiTheme.surfaceWhite,
                      elevation: 8, //Elevación para resaltar el botón sobre el fondo
                      // Sombra con opacidad para evitar el negro puro "sucio"
                      shadowColor: TaxiTheme.primaryDark.withOpacity(0.5),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                    ),
                    onPressed: login, //Al pulsar ejecuta la función de login definida arriba
                    child: const Text(
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