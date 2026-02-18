import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../theme/app_theme.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _userController = TextEditingController();
  final TextEditingController _passController = TextEditingController();
  final supabase = Supabase.instance.client;

  Future<void> login() async {
    try {
      final response = await supabase.auth.signInWithPassword(
        email: _userController.text.trim(),
        password: _passController.text.trim(),
      );

      if (!mounted) return;

      if (response.user != null) {
        Navigator.pushReplacementNamed(context, '/menu');

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Acceso concedido'),
            backgroundColor: TaxiTheme.exito,
          ),
        );
      }
    } on AuthException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.message}'),
          backgroundColor: TaxiTheme.alerta,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error inesperado'),
          backgroundColor: TaxiTheme.alerta,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // TOKEN: Fondo suave
      backgroundColor: TaxiTheme.fondoApp,
      appBar: AppBar(
        title: const Text('TaxiControl', style: TaxiTheme.tituloAppBar),
        centerTitle: true,
        backgroundColor: TaxiTheme.azulPrincipal, // Token del Azul normal
        elevation: 0,
      ),
      body: Center(
        child: SingleChildScrollView(
          // Para que no de error de overflow al abrir el teclado
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Icono decorativo para que no sea tan soso
                const Icon(
                  Icons.local_taxi,
                  size: 80,
                  color: TaxiTheme.azulPrincipal,
                ),
                const SizedBox(height: 30),

                SizedBox(
                  width: 320,
                  child: TextField(
                    controller: _userController,
                    decoration: InputDecoration(
                      labelText: 'Email del Conductor',
                      labelStyle: const TextStyle(
                        color: TaxiTheme.grisTextoSecundario,
                      ),
                      filled: true,
                      fillColor: TaxiTheme.blancoPuro,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(
                          TaxiTheme.radioBoton,
                        ),
                        borderSide: const BorderSide(
                          color: TaxiTheme.grisBordes,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(
                          TaxiTheme.radioBoton,
                        ),
                        borderSide: const BorderSide(
                          color: TaxiTheme.grisBordes,
                        ),
                      ),
                      prefixIcon: const Icon(
                        Icons.email,
                        color: TaxiTheme.azulPrincipal,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 15),
                SizedBox(
                  width: 320,
                  child: TextField(
                    controller: _passController,
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText: 'Contraseña',
                      labelStyle: const TextStyle(
                        color: TaxiTheme.grisTextoSecundario,
                      ),
                      filled: true,
                      fillColor: TaxiTheme.blancoPuro,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(
                          TaxiTheme.radioBoton,
                        ),
                        borderSide: const BorderSide(
                          color: TaxiTheme.grisBordes,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(
                          TaxiTheme.radioBoton,
                        ),
                        borderSide: const BorderSide(
                          color: TaxiTheme.grisBordes,
                        ),
                      ),
                      prefixIcon: const Icon(
                        Icons.lock,
                        color: TaxiTheme.azulPrincipal,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 30),
                SizedBox(
                  width: 280,
                  height: 55,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: TaxiTheme.azulPrincipal, // TOKEN: Azul
                      foregroundColor: TaxiTheme.blancoPuro,
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          TaxiTheme.radioBoton,
                        ), // TOKEN: Redondeo
                      ),
                    ),
                    onPressed: login,
                    child: const Text(
                      'ENTRAR AL SISTEMA',
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
