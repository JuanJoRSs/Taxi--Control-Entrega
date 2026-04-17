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

  // Obtenemos la lista de conductores desde la base de datos
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

  // Diálogo profesional para confirmar el borrado
  Future<void> _confirmarBorrado(Map<String, dynamic> conductor) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        // ✅ FONDO DINÁMICO: El diálogo cambia según el tema
        backgroundColor: Theme.of(context).scaffoldBackgroundColor, 
        title: const Text('¿ELIMINAR CONDUCTOR?', style: TextStyle(color: TaxiTheme.primaryDark, fontWeight: FontWeight.bold)),
        // ✅ TEXTO DINÁMICO: Para que se lea bien en oscuro
        content: Text(
          'Vas a eliminar a ${conductor['nombre']} ${conductor['apellido'] ?? ''}.\n\nSe borrarán sus datos y su cuenta de acceso de forma permanente.', 
          style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color)
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('CANCELAR', style: TextStyle(color: TaxiTheme.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: TaxiTheme.error), // Rojo corporativo
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
            _notificar('Conductor y cuenta eliminados', TaxiTheme.success);
            _obtenerConductores(); 
          }
        } else {
          final errorMsg = response.data['error'] ?? 'Error al eliminar usuario';
          _notificar(errorMsg, TaxiTheme.error);
        }
      } catch (e) {
        debugPrint("Error al borrar: $e");
        if (mounted) {
          _notificar('Error de conexión al eliminar', TaxiTheme.error);
        }
      } finally {
        if (mounted) setState(() => _cargando = false);
      }
    }
  }

  // Formulario elegante para dar de alta
  void _mostrarFormularioAlta() {
    final nombreController = TextEditingController();
    final apellidoController = TextEditingController();
    final emailController = TextEditingController();
    final passController = TextEditingController();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        // ✅ FONDO DINÁMICO: El diálogo de alta cambia según el tema
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(TaxiTheme.radioTarjeta)),
        title: const Text('NUEVO CONDUCTOR', style: TextStyle(color: TaxiTheme.primaryDark, fontWeight: FontWeight.bold, fontSize: 18)),
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
            child: const Text('CANCELAR', style: TextStyle(color: TaxiTheme.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: TaxiTheme.primaryDark,
              foregroundColor: TaxiTheme.surfaceWhite,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(TaxiTheme.radioTarjeta)),
            ),
            onPressed: () => _crearConductor(nombreController.text, apellidoController.text, emailController.text, passController.text),
            child: const Text('GUARDAR'),
          ),
        ],
      ),
    );
  }

  // Estilo de los inputs dentro del diálogo
  Widget _inputAlta(TextEditingController controller, String label, IconData icono, TextInputAction accion, {bool oscuro = false, TextInputType tipo = TextInputType.text}) {
    return TextField(
      controller: controller,
      obscureText: oscuro,
      keyboardType: tipo,
      textInputAction: accion,
      // ✅ COLOR TEXTO INPUT: Para que no se escriba en negro sobre fondo oscuro
      style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: TaxiTheme.textSecondary),
        // ✅ ICONO INPUT: Se vuelve dorado en oscuro o azul en claro
        prefixIcon: Icon(icono, color: Theme.of(context).colorScheme.secondary, size: 20),
        filled: true,
        // ✅ FONDO INPUT: Dinámico
        fillColor: Theme.of(context).cardColor,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(TaxiTheme.radioTarjeta), borderSide: BorderSide.none),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
    );
  }

  Future<void> _crearConductor(String nombre, String apellido, String email, String password) async {
  if (nombre.trim().isEmpty || email.trim().isEmpty || password.length < 6) {
    _notificar('Datos incompletos o contraseña muy corta (mín. 6)', TaxiTheme.warning);
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
        _notificar('Conductor creado correctamente', TaxiTheme.success);
      }
    } else {
      final errorMsg = response.data['error'] ?? 'Error desconocido';
      _notificar('Error: $errorMsg', TaxiTheme.error);
    }

  } catch (e) {
    debugPrint("Error llamando a la función: $e");
    _notificar('Error de conexión con el servidor', TaxiTheme.error);
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
      // ✅ 1. FONDO PANTALLA DINÁMICO
      backgroundColor: Theme.of(context).scaffoldBackgroundColor, 
      appBar: AppBar(
        title: const Text('GESTIÓN DE PLANTILLA', style: TaxiTheme.tituloAppBar),
        centerTitle: true,
        backgroundColor: TaxiTheme.primaryDark,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white), 
        actions: [
          IconButton(
            onPressed: _obtenerConductores,
            icon: const Icon(Icons.refresh, color: TaxiTheme.surfaceWhite),
          ),
        ],
      ),
      body: _cargando
          ? const Center(child: CircularProgressIndicator(color: TaxiTheme.accentGold))
          : _conductores.isEmpty
              ? const Center(child: Text('No hay conductores registrados.', style: TextStyle(color: TaxiTheme.textSecondary)))
              : ListView.separated(
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                  itemCount: _conductores.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final c = _conductores[index];
                    return Container(
                      // ✅ 2. FONDO TARJETA DINÁMICO
                      decoration: TaxiTheme.decoracionTarjeta.copyWith(
                        color: Theme.of(context).cardColor,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ), 
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: TaxiTheme.primaryDark.withOpacity(0.1),
                          // ✅ ICONO AVATAR: Se adapta al tema
                          child: Icon(Icons.person, color: Theme.of(context).colorScheme.secondary),
                        ),
                        // ✅ 3. COLOR DE TEXTO DINÁMICO
                        title: Text('${c['nombre']} ${c['apellido'] ?? ''}', style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).textTheme.bodyLarge?.color)),
                        subtitle: Text(c['email'] ?? 'Sin email', style: const TextStyle(color: TaxiTheme.textSecondary)),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline, color: TaxiTheme.error),
                          onPressed: () => _confirmarBorrado(c),
                        ),
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: TaxiTheme.primaryDark,
        onPressed: _mostrarFormularioAlta,
        child: const Icon(Icons.add, color: TaxiTheme.surfaceWhite),
      ),
    );
  }
}