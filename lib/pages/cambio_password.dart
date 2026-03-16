import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PantallaCambioPassword extends StatefulWidget {
  const PantallaCambioPassword({Key? key}) : super(key: key);

  @override
  State<PantallaCambioPassword> createState() => _PantallaCambioPasswordState();
}

class _PantallaCambioPasswordState extends State<PantallaCambioPassword> {
  // Controlador para leer lo que el usuario escribe en la caja de texto
  final _controladorPassword = TextEditingController();
  bool _cargando = false;

  Future<void> _actualizarContrasena() async {
    final nuevaPassword = _controladorPassword.text;

    // Comprobamos que la contraseña no esté vacía y sea segura (mínimo 6 caracteres)
    if (nuevaPassword.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('La contraseña debe tener al menos 6 caracteres')),
      );
      return;
    }

    setState(() { _cargando = true; });

    try {
      final supabase = Supabase.instance.client;
      final usuarioActual = supabase.auth.currentUser;

      if (usuarioActual != null) {
        // PASO 1: Actualizamos la tabla interna de Auth de Supabase con la nueva clave
        await supabase.auth.updateUser(
          UserAttributes(password: nuevaPassword),
        );

        // PASO 2: Actualizamos nuestra tabla SQL 'conductores' para apagar el interruptor
        await supabase
            .from('conductores')
            .update({'debe_cambiar_pass': false}) // Ya no necesita cambiarla
            .eq('auth_id', usuarioActual.id); // Solo al usuario que ha iniciado sesión

        // PASO 3: Si todo va bien, lo enviamos al menú principal
        if (mounted) {
          Navigator.pushReplacementNamed(context, '/menu');
        }
      }
    } catch (e) {
      // Si hay un error, lo mostramos en pantalla
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cambiar la contraseña: $e')),
        );
      }
    } finally {
      if (mounted) setState(() { _cargando = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cambio de Contraseña Obligatorio'),
        // Quitamos el botón de volver atrás para que no puedan saltarse este paso
        automaticallyImplyLeading: false, 
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Por seguridad, debes cambiar la contraseña genérica por una personal antes de continuar.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 20),
            
            // Caja de texto para escribir la contraseña
            TextField(
              controller: _controladorPassword,
              obscureText: true, // Oculta el texto con asteriscos
              decoration: const InputDecoration(
                labelText: 'Nueva Contraseña',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            
            // Botón para guardar
            SizedBox(
              width: double.infinity, // Ocupa todo el ancho
              height: 50,
              child: ElevatedButton(
                onPressed: _cargando ? null : _actualizarContrasena,
                child: _cargando
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Guardar y Entrar', style: TextStyle(fontSize: 18)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}