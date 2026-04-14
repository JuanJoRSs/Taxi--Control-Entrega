import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import '../theme/app_theme.dart';

class Agencias extends StatefulWidget {
  const Agencias({super.key});

  @override
  State<Agencias> createState() => _AgenciasState();
}

class _AgenciasState extends State<Agencias> {
  final _supabase = Supabase.instance.client; // Conexión a la base de datos
  bool _estaCargando = true;
  List<dynamic> _agencias = []; //Lista de estado para guardar las agencias que se muestran en la pantalla, recogiendo la información de la base de datos.

  @override
  void initState() {
    super.initState();
    _cargarAgencias(); // Cargamos las agencias al iniciar la pantalla
  }

  Future<void> _cargarAgencias() async { //Funcion que consulta la tabla de agencias, ordenando por fecha, y si coincide, por hora
    setState(() => _estaCargando = true);
    try {
      final data = await _supabase
          .from('agencias')
          .select('*')
          .order('fecha', ascending: true)
          .order('hora', ascending: true);

      setState(() => _agencias = data); //Metemos dentro de _agencias la información traída de la BBDD
    } catch (e) {
      _mostrarMensaje('Error al cargar agencias: $e', isError: true);
    } finally {
      setState(() => _estaCargando = false);
    }
  }

  Future<void> _eliminarAgencia(dynamic agencia) async { //Función de eliminar agencia con modal de confirmación
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog( //**Alert dialog es el modal**
        backgroundColor: TaxiTheme.backgroundLight,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Eliminar servicio', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Text(
          '¿Eliminar el servicio de ${agencia['empresa']}?\n'
          'Fecha: ${DateFormat('dd/MM/yyyy').format(DateTime.parse(agencia['fecha']))}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false), //Al pulsar en eliminar se eliminar y el pop lleva a la pantalla anterior al modal (agencias propiamente dicho) 
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: TaxiTheme.error),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Eliminar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmar != true) return; //Si el usuario no confirma la eliminación, se sale de la función sin hacer nada

    try {
      await _supabase.from('agencias').delete().eq('id', agencia['id']);
      _mostrarMensaje('Servicio eliminado');
      _cargarAgencias();
    } catch (e) {
      _mostrarMensaje('Error al eliminar: $e', isError: true);
    }
  }

  void _mostrarMensaje(String texto, {bool isError = false}) { // Función para mostrar mensajes de éxito o error al usuario, dependiendo de la acción. El texto se pasa por parámetro, y el color se decide con el booleano isError
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(texto),
        backgroundColor: isError ? TaxiTheme.error : TaxiTheme.success,
      ),
    );
  }

  void _abrirFormulario({dynamic agencia}) async { //Función que redirige a la pantalla de formulario, y si se le pasa una agencia por parámetro, el formulario se abre en modo edición con los datos de esa agencia. Si no se le pasa nada, se abre en modo creación.
    final resultado = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => _AgenciaForm(agencia: agencia),
      ),
    );
    if (resultado == true) _cargarAgencias();
  }

  @override
  Widget build(BuildContext context) {
    final agencias = _agencias;

    return Scaffold(
      backgroundColor: TaxiTheme.backgroundLight,
      appBar: AppBar(
        title: const Text('GESTIÓN DE AGENCIAS', style: TaxiTheme.tituloAppBar),
        backgroundColor: TaxiTheme.primaryDark,
        centerTitle: true,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _cargarAgencias,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: TaxiTheme.accentGold,
        foregroundColor: TaxiTheme.primaryDark,
        onPressed: () => _abrirFormulario(),
        icon: const Icon(Icons.add),
        label: const Text('Nuevo Servicio', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: Column(
        children: [
          // Contador
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 4),
            child: Row(
              children: [
                Text(
                  '${agencias.length} servicio${agencias.length != 1 ? 's' : ''}',
                  style: TextStyle(
                    color: TaxiTheme.primaryDark.withOpacity(0.6),
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),

          // Lista
          Expanded(
            child: _estaCargando
                ? const Center(
                    child: CircularProgressIndicator(color: TaxiTheme.accentGold),
                  )
                : agencias.isEmpty
                    ? _emptyState()
                    : RefreshIndicator(
                        color: TaxiTheme.accentGold,
                        onRefresh: _cargarAgencias,
                        child: ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                          itemCount: agencias.length,
                          itemBuilder: (_, i) => _tarjetaAgencia(agencias[i]),
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _tarjetaAgencia(dynamic a) {
    final fecha = DateTime.parse(a['fecha']);
    final esHoy = DateFormat('yyyy-MM-dd').format(fecha) ==
        DateFormat('yyyy-MM-dd').format(DateTime.now());
    final horaStr = (a['hora'] as String).substring(0, 5);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 7),
      decoration: TaxiTheme.decoracionTarjeta.copyWith(
        border: esHoy ? Border.all(color: TaxiTheme.accentGold, width: 2) : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _abrirFormulario(agencia: a),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: TaxiTheme.primaryDark,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.business, color: TaxiTheme.accentGold, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                a['empresa'] ?? '',
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                  color: TaxiTheme.primaryDark,
                                ),
                              ),
                            ),
                            if (esHoy)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: TaxiTheme.accentGold,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: const Text(
                                  'HOY',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w900,
                                    color: TaxiTheme.primaryDark,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 3),
                        Row(
                          children: [
                            const Icon(Icons.location_on_outlined, size: 13, color: Colors.grey),
                            const SizedBox(width: 3),
                            Expanded(
                              child: Text(
                                a['lugar_recogida'] ?? '',
                                style: const TextStyle(fontSize: 12, color: Colors.grey),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 22),
                    onPressed: () => _eliminarAgencia(a),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 10),
              Row(
                children: [
                  _chip(Icons.calendar_today_outlined, DateFormat('dd/MM/yyyy').format(fecha)),
                  const SizedBox(width: 8),
                  _chip(Icons.access_time_outlined, horaStr),
                  const SizedBox(width: 8),
                  _chip(Icons.people_outline, '${a['num_pasajeros']} pax'),
                  const Spacer(),
                  Text(
                    '${double.parse(a['precio'].toString()).toStringAsFixed(2)} €',
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w900,
                      color: TaxiTheme.primaryDark,
                    ),
                  ),
                ],
              ),
              if (a['notes'] != null && (a['notes'] as String).isNotEmpty) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.notes_outlined, size: 13, color: Colors.grey),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        a['notas'],
                        style: const TextStyle(fontSize: 11, color: Colors.grey),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _chip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: TaxiTheme.primaryDark.withOpacity(0.07),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: TaxiTheme.primaryDark),
          const SizedBox(width: 4),
          Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _emptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.business_center_outlined, size: 72, color: Colors.grey.withOpacity(0.4)),
          const SizedBox(height: 16),
          const Text(
            'No hay servicios registrados',
            style: TextStyle(fontSize: 16, color: Colors.grey, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          const Text('Pulsa + para añadir uno nuevo', style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }
}

//FORMULUARIO DE CREAR Y EDITAR AGENCIA
class _AgenciaForm extends StatefulWidget {
  final dynamic agencia;
  const _AgenciaForm({this.agencia});

  @override
  State<_AgenciaForm> createState() => _AgenciaFormState();
}

class _AgenciaFormState extends State<_AgenciaForm> {
  final _supabase = Supabase.instance.client;
  final _formKey = GlobalKey<FormState>();
  bool _guardando = false;

  late TextEditingController _empresaCtrl;
  late TextEditingController _lugarCtrl;
  late TextEditingController _precioCtrl;
  late TextEditingController _pasajerosCtrl;
  late TextEditingController _notasCtrl;
  DateTime? _fecha;
  TimeOfDay? _hora;

  bool get _esEdicion => widget.agencia != null;

  @override
  void initState() {
    super.initState();
    final a = widget.agencia;
    _empresaCtrl = TextEditingController(text: a?['empresa'] ?? '');
    _lugarCtrl = TextEditingController(text: a?['lugar_recogida'] ?? '');
    _precioCtrl = TextEditingController(
      text: a != null ? double.parse(a['precio'].toString()).toStringAsFixed(2) : '',
    );
    _pasajerosCtrl = TextEditingController(
      text: a != null ? a['num_pasajeros'].toString() : '',
    );
    _notasCtrl = TextEditingController(text: a?['notas'] ?? '');

    if (a != null) {
      _fecha = DateTime.parse(a['fecha']);
      final partes = (a['hora'] as String).split(':');
      _hora = TimeOfDay(hour: int.parse(partes[0]), minute: int.parse(partes[1]));
    }
  }

  @override
  void dispose() {
    _empresaCtrl.dispose();
    _lugarCtrl.dispose();
    _precioCtrl.dispose();
    _pasajerosCtrl.dispose();
    _notasCtrl.dispose();
    super.dispose();
  }

  Future<void> _seleccionarFecha(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _fecha ?? DateTime.now(),
      firstDate: DateTime(2024),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(primary: TaxiTheme.primaryDark),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) setState(() => _fecha = picked);
  }

  Future<void> _seleccionarHora(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _hora ?? TimeOfDay.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(primary: TaxiTheme.primaryDark),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) setState(() => _hora = picked);
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;
    if (_fecha == null) {
      _mostrarMensaje('Selecciona una fecha', isError: true);
      return;
    }
    if (_hora == null) {
      _mostrarMensaje('Selecciona una hora', isError: true);
      return;
    }

    setState(() => _guardando = true);

    try {
      final datos = {
        'empresa': _empresaCtrl.text.trim(),
        'lugar_recogida': _lugarCtrl.text.trim(),
        'precio': double.parse(_precioCtrl.text.replaceAll(',', '.')),
        'num_pasajeros': int.parse(_pasajerosCtrl.text.trim()),
        'hora': '${_hora!.hour.toString().padLeft(2, '0')}:${_hora!.minute.toString().padLeft(2, '0')}:00',
        'fecha': DateFormat('yyyy-MM-dd').format(_fecha!),
        'notas': _notasCtrl.text.trim().isEmpty ? null : _notasCtrl.text.trim(),
      };

      if (_esEdicion) {
        await _supabase
            .from('agencias')
            .update(datos)
            .eq('id', widget.agencia!['id']);
        _mostrarMensaje('Servicio actualizado');
      } else {
        await _supabase.from('agencias').insert(datos);
        _mostrarMensaje('Servicio creado');
      }

      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      _mostrarMensaje('Error al guardar: $e', isError: true);
    } finally {
      setState(() => _guardando = false);
    }
  }

  void _mostrarMensaje(String texto, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(texto),
        backgroundColor: isError ? TaxiTheme.error : TaxiTheme.success,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TaxiTheme.backgroundLight,
      appBar: AppBar(
        title: Text(
          _esEdicion ? 'EDITAR SERVICIO' : 'NUEVO SERVICIO',
          style: TaxiTheme.tituloAppBar,
        ),
        backgroundColor: TaxiTheme.primaryDark,
        centerTitle: true,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _guardando
          ? const Center(child: CircularProgressIndicator(color: TaxiTheme.accentGold))
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 30),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 1. FECHA Y HORA
                    _seccionTitulo('1. FECHA Y HORA DEL SERVICIO'),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _botonFechaPro(
                            label: _fecha == null
                                ? 'Fecha del servicio'
                                : DateFormat('dd/MM/yyyy').format(_fecha!),
                            icon: Icons.calendar_today_outlined,
                            seleccionado: _fecha != null,
                            onTap: () => _seleccionarFecha(context),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: _botonFechaPro(
                            label: _hora == null
                                ? 'Hora del servicio'
                                : _hora!.format(context),
                            icon: Icons.access_time_outlined,
                            seleccionado: _hora != null,
                            onTap: () => _seleccionarHora(context),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 30),

                    // 2. DATOS DE LA AGENCIA
                    _seccionTitulo('2. DATOS DE LA AGENCIA'),
                    const SizedBox(height: 12),
                    _campoTexto(
                      controller: _empresaCtrl,
                      label: 'Empresa / Agencia',
                      icon: Icons.business_outlined,
                      validator: (v) =>
                          v == null || v.trim().isEmpty ? 'Campo obligatorio' : null,
                    ),
                    const SizedBox(height: 14),
                    _campoTexto(
                      controller: _lugarCtrl,
                      label: 'Lugar de recogida',
                      icon: Icons.location_on_outlined,
                      hint: 'Ej: Aeropuerto T4, Madrid',
                      validator: (v) =>
                          v == null || v.trim().isEmpty ? 'Campo obligatorio' : null,
                    ),

                    const SizedBox(height: 30),

                    // 3. DETALLES DEL SERVICIO
                    _seccionTitulo('3. DETALLES DEL SERVICIO'),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _campoTexto(
                            controller: _precioCtrl,
                            label: 'Precio (€)',
                            icon: Icons.euro_outlined,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                            ],
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) return 'Obligatorio';
                              if (double.tryParse(v.replaceAll(',', '.')) == null) {
                                return 'Número inválido';
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: _campoTexto(
                            controller: _pasajerosCtrl,
                            label: 'Nº Pasajeros',
                            icon: Icons.people_outline,
                            keyboardType: TextInputType.number,
                            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) return 'Obligatorio';
                              if (int.tryParse(v) == null) return 'Inválido';
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    _campoTexto(
                      controller: _notasCtrl,
                      label: 'Notas (opcional)',
                      icon: Icons.notes_outlined,
                      hint: 'Instrucciones especiales, información adicional...',
                      maxLines: 3,
                    ),

                    const SizedBox(height: 50),

                    SizedBox(
                      width: double.infinity,
                      height: 58,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: TaxiTheme.accentGold,
                          foregroundColor: TaxiTheme.primaryDark,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          elevation: 4,
                          shadowColor: Colors.black.withOpacity(0.3),
                        ),
                        onPressed: _guardando ? null : _guardar,
                        icon: Icon(_esEdicion ? Icons.save_outlined : Icons.check_circle_outline),
                        label: Text(
                          _esEdicion ? 'GUARDAR CAMBIOS' : 'CREAR SERVICIO',
                          style: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 0.8),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _seccionTitulo(String titulo) => Text(
        titulo,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w800,
          color: TaxiTheme.primaryDark,
          letterSpacing: 1.1,
        ),
      );

  Widget _botonFechaPro({
    required String label,
    required IconData icon,
    required bool seleccionado,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        height: 55,
        decoration: TaxiTheme.decoracionTarjeta.copyWith(
          border: seleccionado ? Border.all(color: TaxiTheme.accentGold, width: 2) : null,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 16,
              color: seleccionado ? TaxiTheme.accentGold : TaxiTheme.primaryDark,
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                label,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                  color: seleccionado
                      ? TaxiTheme.primaryDark
                      : TaxiTheme.primaryDark.withOpacity(0.5),
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _campoTexto({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? hint,
    TextInputType keyboardType = TextInputType.text,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      validator: validator,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, color: TaxiTheme.primaryDark, size: 20),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: TaxiTheme.primaryDark, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: TaxiTheme.error),
        ),
        contentPadding: EdgeInsets.symmetric(
          horizontal: 14,
          vertical: maxLines > 1 ? 14 : 0,
        ),
      ),
    );
  }
}