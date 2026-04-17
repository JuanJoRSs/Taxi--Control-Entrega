// Importación de librerías para la interfaz, base de datos y formato de fechas
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import '../theme/app_theme.dart';

class Facturacion extends StatefulWidget {
  const Facturacion({super.key});

  @override
  State<Facturacion> createState() => _FacturacionScreenState();
}

class _FacturacionScreenState extends State<Facturacion> {
  // Inicialización de herramientas: base de datos, controlador de texto y clave de formulario
  final _supabase = Supabase.instance.client;
  final _montoController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  
  // Variables de control de interfaz y permisos
  bool _cargando = true;
  bool _mostrandoFormulario = false;
  bool _esAdmin = false;
  String _nombreAutor = "Admin";
  
  // Listas para almacenar los datos de la base de datos
  List<dynamic> _registros = [];
  List<dynamic> _listaConductores = [];
  String? _conductorSeleccionado; 

  // Definición del rango de fechas inicial (desde el día 1 del mes actual hasta hoy)
  DateTime _fechaInicio = DateTime(DateTime.now().year, DateTime.now().month, 1);
  DateTime _fechaFin = DateTime.now();

  @override
  void initState() {
    super.initState();
    // Al cargar la pantalla, verificamos el perfil del usuario y obtenemos datos
    _inicializarPantalla();
  }

  @override
  void dispose() {
    // Limpieza del controlador para liberar memoria al cerrar la pantalla
    _montoController.dispose();
    super.dispose();
  }

  // Verifica si el usuario actual tiene permisos de administrador
  Future<void> _inicializarPantalla() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return;

      // Consulta a la tabla conductores para saber el nombre y rol del usuario
      final data = await _supabase
          .from('conductores')
          .select('nombre, apellido, es_admin')
          .eq('auth_id', user.id)
          .single();

      if (mounted) {
        setState(() {
          _esAdmin = data['es_admin'] ?? false;
          _nombreAutor = "${data['nombre']} ${data['apellido']}";
        });
      }

      // Si es administrador, carga la lista de todos los conductores para permitir filtrar
      if (_esAdmin) {
        final dataConductores = await _supabase
            .from('conductores')
            .select('auth_id, nombre, apellido')
            .order('nombre');
        setState(() => _listaConductores = dataConductores);
      }

      // Una vez configurado el perfil, descargamos los registros de facturación
      await _obtenerDatos();
    } catch (e) {
      _notificar("Error al inicializar", TaxiTheme.error);
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  // Descarga los registros de facturación aplicando filtros de fecha y usuario
  Future<void> _obtenerDatos() async {
    setState(() => _cargando = true);
    try {
      final fIni = DateFormat('yyyy-MM-dd').format(_fechaInicio);
      final fFin = DateFormat('yyyy-MM-dd').format(_fechaFin);

      var query = _supabase.from('facturacion').select();

      // Filtro de seguridad: el conductor normal solo ve sus datos, el admin puede elegir
      if (!_esAdmin) {
        query = query.eq('creado_por', _supabase.auth.currentUser!.id);
      } else if (_conductorSeleccionado != null) {
        query = query.eq('creado_por', _conductorSeleccionado!);
      }

      // Ejecución de la consulta con el rango de fechas seleccionado
      final data = await query
          .gte('fecha', fIni)
          .lte('fecha', fFin)
          .order('created_at', ascending: false);
      
      if (mounted) setState(() => _registros = data);
    } catch (e) {
      _notificar("Error al cargar datos", TaxiTheme.error);
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  // Abre el selector de rango de fechas de Android/iOS
  Future<void> _seleccionarRango(BuildContext context) async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      initialDateRange: DateTimeRange(start: _fechaInicio, end: _fechaFin),
      firstDate: DateTime(2024),
      lastDate: DateTime.now(),
      helpText: 'SELECCIONA EL PERIODO',
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(primary: TaxiTheme.primaryDark),
        ),
        child: Center(child: child!),
      ),
    );

    if (picked != null) {
      setState(() {
        _fechaInicio = picked.start;
        _fechaFin = picked.end;
      });
      await _obtenerDatos();
    }
  }

  // Guarda una nueva entrada de dinero en la base de datos
  Future<void> _guardarFacturacion() async {
    // Validación de campos vacíos
    if (!_formKey.currentState!.validate()) return;

    // Conversión del texto a número decimal
    final monto = double.tryParse(_montoController.text.replaceAll(',', '.'));
    if (monto == null || monto <= 0) {
      _notificar("Introduce un monto válido", TaxiTheme.warning);
      return;
    }

    setState(() => _cargando = true);
    try {
      // Inserción de datos en Supabase con la ID del autor y la fecha actual
      await _supabase.from('facturacion').insert({
        'monto': monto,
        'creado_por': _supabase.auth.currentUser!.id,
        'autor_nombre': _nombreAutor,
        'fecha': DateTime.now().toIso8601String().split('T')[0],
      });
      
      // Limpieza de interfaz tras guardar con éxito
      _montoController.clear();
      FocusScope.of(context).unfocus();
      setState(() => _mostrandoFormulario = false);
      await _obtenerDatos();
      _notificar("Facturación guardada", TaxiTheme.success);
    } catch (e) {
      _notificar("Error al guardar", TaxiTheme.error);
    }
  }

  // Cálculo automático del total recaudado en el periodo visible
  double get _totalSumado => _registros.fold(0, (sum, item) => sum + (item['monto'] ?? 0));

  // Función auxiliar para mostrar avisos rápidos en pantalla
  void _notificar(String msg, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg), 
      backgroundColor: color, 
      behavior: SnackBarBehavior.floating
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Uso de colores dinámicos que cambian automáticamente en modo oscuro
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(_mostrandoFormulario ? 'NUEVA ENTRADA' : 'FACTURACIÓN', style: TaxiTheme.tituloAppBar),
        backgroundColor: TaxiTheme.primaryDark,
        centerTitle: true,
        elevation: 0,
        leading: _mostrandoFormulario 
          ? IconButton(
              icon: Icon(Icons.arrow_back, color: Theme.of(context).colorScheme.onPrimary), 
              onPressed: () => setState(() => _mostrandoFormulario = false)
            )
          : null,
      ),
      // Intercambio de vista entre la lista de registros y el formulario de entrada
      body: _mostrandoFormulario ? _buildFormularioArea() : _buildPrincipalArea(),
      floatingActionButton: _mostrandoFormulario 
          ? null 
          : FloatingActionButton.extended(
              backgroundColor: TaxiTheme.accentGold,
              onPressed: () => setState(() => _mostrandoFormulario = true),
              icon: const Icon(Icons.add, color: TaxiTheme.primaryDark),
              label: Text("AÑADIR", style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color, fontWeight: FontWeight.bold)),
            ),
    );
  }

  // Construcción de la vista principal con filtros y listado
  Widget _buildPrincipalArea() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              // Solo el administrador ve el selector de conductores
              if (_esAdmin) ...[
                _buildSelectorConductor(),
                const SizedBox(height: 12),
              ],
              _buildTarjetaRango(),
            ],
          ),
        ),
        // Solo el administrador ve el recuadro con la suma total
        if (_esAdmin) _buildResumenAdmin(),
        Expanded(child: _buildListaRegistros()),
      ],
    );
  }

  // Construcción de la vista del formulario para introducir nuevos montos
  Widget _buildFormularioArea() {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(25),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("MONTO RECAUDADO", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Theme.of(context).textTheme.bodyLarge?.color, letterSpacing: 1.2)),
                  const SizedBox(height: 15),
                  TextFormField(
                    controller: _montoController,
                    autofocus: true,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Theme.of(context).textTheme.bodyLarge?.color),
                    decoration: InputDecoration(
                      hintText: '0.00',
                      prefixIcon: Icon(Icons.euro, color: TaxiTheme.success, size: 30),
                      filled: true,
                      fillColor: Theme.of(context).cardColor,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
                      contentPadding: const EdgeInsets.symmetric(vertical: 20),
                    ),
                    validator: (value) => (value == null || value.isEmpty) ? 'Campo obligatorio' : null,
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Icon(Icons.info_outline, size: 16, color: Theme.of(context).textTheme.bodyLarge?.color),
                      const SizedBox(width: 8),
                      Text("Fecha de registro: ${DateFormat('dd/MM/yyyy').format(DateTime.now())}", 
                        style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color)),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
        _buildBotonGuardarAccion(),
      ],
    );
  }

  // Botón inferior de confirmación de guardado
  Widget _buildBotonGuardarAccion() {
    return Container(
      padding: EdgeInsets.only(left: 20, right: 20, bottom: MediaQuery.of(context).padding.bottom + 20, top: 20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
      ),
      child: SizedBox(
        width: double.infinity,
        height: 55,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: TaxiTheme.success,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          ),
          onPressed: _cargando ? null : _guardarFacturacion,
          child: _cargando 
              ? CircularProgressIndicator(color: Theme.of(context).colorScheme.onPrimary)
              : const Text("CONFIRMAR Y GUARDAR", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        ),
      ),
    );
  }

  // Componente visual para la selección del rango de fechas
  Widget _buildTarjetaRango() {
    return InkWell(
      onTap: () => _seleccionarRango(context),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
        decoration: TaxiTheme.decoracionTarjeta.copyWith(color: Theme.of(context).cardColor),
        child: Row(
          children: [
            Icon(Icons.calendar_month, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 15),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("PERIODO SELECCIONADO", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Theme.of(context).textTheme.bodyMedium?.color)),
                Text("${DateFormat('dd MMM').format(_fechaInicio)} — ${DateFormat('dd MMM').format(_fechaFin)}", 
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Theme.of(context).textTheme.bodyLarge?.color)),
              ],
            ),
            const Spacer(),
            const Icon(Icons.tune, size: 20, color: TaxiTheme.accentGold),
          ],
        ),
      ),
    );
  }

  // Menú desplegable para que el administrador filtre por conductor
  Widget _buildSelectorConductor() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15),
      decoration: TaxiTheme.decoracionTarjeta.copyWith(color: Theme.of(context).cardColor),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          isExpanded: true,
          dropdownColor: Theme.of(context).cardColor,
          value: _conductorSeleccionado,
          hint: Text('Todos los conductores', style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color)),
          items: [
            DropdownMenuItem<String>(
              value: null,
              child: Text('Todos los conductores', style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color)),
            ),
            ..._listaConductores.map((c) => DropdownMenuItem<String>(
              value: c['auth_id'].toString(),
              child: Text("${c['nombre']} ${c['apellido'] ?? ''}", style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color)),
            ))
          ],
          onChanged: (val) {
            setState(() => _conductorSeleccionado = val);
            _obtenerDatos();
          },
        ),
      ),
    );
  }

  // Panel informativo con el total de ingresos
  Widget _buildResumenAdmin() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(color: TaxiTheme.primaryDark, borderRadius: BorderRadius.circular(15)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('TOTAL RECAUDADO: ', style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color, fontSize: 14)),
          Text('${_totalSumado.toStringAsFixed(2)}€', style: TextStyle(color: TaxiTheme.accentGold, fontWeight: FontWeight.bold, fontSize: 18)),
        ],
      ),
    );
  }

  // Generación dinámica de la lista de registros mediante un constructor de lista
  Widget _buildListaRegistros() {
    if (_cargando && !_mostrandoFormulario) return const Center(child: CircularProgressIndicator());
    if (_registros.isEmpty) return const Center(child: Text("No hay registros disponibles"));

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: _registros.length,
      itemBuilder: (context, index) {
        final reg = _registros[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: TaxiTheme.decoracionTarjeta.copyWith(color: Theme.of(context).cardColor),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
            leading: Icon(Icons.receipt_long, color: TaxiTheme.success),
            title: Text('${reg['monto']} €', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Theme.of(context).textTheme.bodyLarge?.color)),
            subtitle: Text('${reg['autor_nombre']} • ${DateFormat('dd/MM/yy').format(DateTime.parse(reg['fecha']))}', style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color)),
            trailing: Icon(Icons.chevron_right, size: 18, color: Theme.of(context).iconTheme.color),
          ),
        );
      },
    );
  }
}