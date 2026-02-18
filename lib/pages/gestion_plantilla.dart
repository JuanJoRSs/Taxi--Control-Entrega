import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../theme/app_theme.dart'; 

class GestionPlantilla extends StatefulWidget {
  const GestionPlantilla({super.key});

  @override
  State<GestionPlantilla> createState() => _GestionPlantillaState();
}

class _GestionPlantillaState extends State<GestionPlantilla> {
  final _supabase = Supabase.instance.client;
  List<dynamic> _conductores = [];
  bool _cargando = true;

  @override
  void initState() {
    super.initState();
    _obtenerConductores();
  }

  Future<void> _obtenerConductores() async {
    try {
      setState(() => _cargando = true);
      final conductores = await _supabase
          .from('conductores')
          .select()
          .or('es_admin.eq.false, es_admin.is.null')
          .order('nombre', ascending: true);

      if (mounted) {
        setState(() {
          _conductores = conductores;
          _cargando = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _cargando = false);
    }
  }

  Future<void> _confirmarBorrado(Map<String, dynamic> conductor) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('¿ELIMINAR CONDUCTOR?'),
        content: Text('Vas a eliminar a ${conductor['nombre']} ${conductor['apellido'] ?? ''}.\n\nSe borrarán sus datos y su cuenta de acceso de forma permanente.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('CANCELAR', style: TextStyle(color: TaxiTheme.grisTextoSecundario)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: TaxiTheme.alerta),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('ELIMINAR', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmar == true) {
      try {
        setState(() => _cargando = true);

        final response = await _supabase.functions.invoke(
          'eliminar-conductor-admin',
          body: {
            'auth_id': conductor['auth_id'],
          },
        );

        if (response.status == 200) {
          if (mounted) {
            _notificar('Conductor y cuenta eliminados', TaxiTheme.exito);
            _obtenerConductores(); 
          }
        } else {
          final errorMsg = response.data['error'] ?? 'Error al eliminar usuario';
          _notificar(errorMsg, TaxiTheme.alerta);
        }
      } catch (e) {
        debugPrint("Error al borrar: $e");
        if (mounted) {
          _notificar('Error de conexión al eliminar', TaxiTheme.alerta);
        }
      } finally {
        if (mounted) setState(() => _cargando = false);
      }
    }
  }

  void _mostrarFormularioAlta() {
    final nombreController = TextEditingController();
    final apellidoController = TextEditingController();
    final emailController = TextEditingController();
    final passController = TextEditingController();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: TaxiTheme.blancoPuro,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(TaxiTheme.radioTarjeta)),
        title: const Text('NUEVO CONDUCTOR', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _inputAlta(nombreController, 'Nombre', Icons.person_outline, TextInputAction.next),
              const SizedBox(height: 12),
              _inputAlta(apellidoController, 'Apellido', Icons.person_outline, TextInputAction.next),
              const SizedBox(height: 12),
              _inputAlta(emailController, 'Email', Icons.email_outlined, TextInputAction.next, tipo: TextInputType.emailAddress),
              const SizedBox(height: 12),
              _inputAlta(passController, 'Contraseña (mín. 6)', Icons.lock_outline, TextInputAction.done, oscuro: true),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCELAR', style: TextStyle(color: TaxiTheme.grisTextoSecundario)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: TaxiTheme.azulPrincipal,
              foregroundColor: TaxiTheme.blancoPuro,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(TaxiTheme.radioBoton)),
            ),
            onPressed: () => _crearConductor(nombreController.text, apellidoController.text, emailController.text, passController.text),
            child: const Text('GUARDAR'),
          ),
        ],
      ),
    );
  }

  Widget _inputAlta(TextEditingController controller, String label, IconData icono, TextInputAction accion, {bool oscuro = false, TextInputType tipo = TextInputType.text}) {
    return TextField(
      controller: controller,
      obscureText: oscuro,
      keyboardType: tipo,
      textInputAction: accion,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icono, color: TaxiTheme.azulPrincipal, size: 20),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(TaxiTheme.radioBoton)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
    );
  }

  Future<void> _crearConductor(String nombre, String apellido, String email, String password) async {
  if (nombre.trim().isEmpty || email.trim().isEmpty || password.length < 6) {
    _notificar('Datos incompletos o contraseña muy corta (mín. 6)', TaxiTheme.alerta);
    return;
  }

  try {
    setState(() => _cargando = true);

    final response = await _supabase.functions.invoke(
      'crear-conductor-admin',
      body: {
        'nombre': nombre.trim(),
        'apellido': apellido.trim(),
        'email': email.trim(),
        'password': password,
      },
    );

    if (response.status == 200) {
      if (mounted) {
        Navigator.of(context).pop(); 
        _obtenerConductores(); 
        _notificar('Conductor creado correctamente', TaxiTheme.exito);
      }
    } else {
      // Si la función devuelve un error (ej. email ya existe)
      final errorMsg = response.data['error'] ?? 'Error desconocido';
      _notificar('Error: $errorMsg', TaxiTheme.alerta);
    }

  } catch (e) {
    debugPrint("Error llamando a la función: $e");
    _notificar('Error de conexión con el servidor', TaxiTheme.alerta);
  } finally {
    if (mounted) setState(() => _cargando = false);
  }
}

  void _notificar(String mensaje, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(mensaje), backgroundColor: color));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TaxiTheme.fondoApp,
      appBar: AppBar(
        title: const Text('GESTIÓN DE PLANTILLA', style: TaxiTheme.tituloAppBar),
        centerTitle: true,
        backgroundColor: TaxiTheme.azulPrincipal,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: _obtenerConductores,
            icon: const Icon(Icons.refresh, color: TaxiTheme.blancoPuro),
          ),
        ],
      ),
      body: _cargando
          ? const Center(child: CircularProgressIndicator(color: TaxiTheme.azulPrincipal))
          : _conductores.isEmpty
              ? const Center(child: Text('No hay conductores registrados.', style: TaxiTheme.subtitulo))
              : ListView.separated(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: _conductores.length,
                  separatorBuilder: (context, index) => const Divider(height: 1, indent: 70),
                  itemBuilder: (context, index) {
                    final c = _conductores[index];
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: TaxiTheme.azulPrincipal.withOpacity(0.1),
                        child: const Icon(Icons.person, color: TaxiTheme.azulPrincipal),
                      ),
                      title: Text('${c['nombre']} ${c['apellido'] ?? ''}', style: const TextStyle(fontWeight: FontWeight.bold, color: TaxiTheme.grisTextoPrincipal)),
                      subtitle: Text(c['email'] ?? 'Sin email', style: TaxiTheme.subtitulo),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete_outline, color: TaxiTheme.alerta),
                        onPressed: () => _confirmarBorrado(c),
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: TaxiTheme.azulPrincipal,
        onPressed: _mostrarFormularioAlta,
        child: const Icon(Icons.add, color: TaxiTheme.blancoPuro),
      ),
    );
  }
}
