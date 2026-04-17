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
  final _supabase = Supabase.instance.client;
  final _montoController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  
  bool _cargando = true;
  bool _mostrandoFormulario = false;
  bool _esAdmin = false;
  String _nombreAutor = "Admin";
  
  List<dynamic> _registros = [];
  List<dynamic> _listaConductores = [];
  String? _conductorSeleccionado; 

  DateTime _fechaInicio = DateTime(DateTime.now().year, DateTime.now().month, 1);
  DateTime _fechaFin = DateTime.now();

  @override
  void initState() {
    super.initState();
    _inicializarPantalla();
  }

  @override
  void dispose() {
    _montoController.dispose();
    super.dispose();
  }

  Future<void> _inicializarPantalla() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return;

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

      if (_esAdmin) {
        final dataConductores = await _supabase
            .from('conductores')
            .select('auth_id, nombre, apellido')
            .order('nombre');
        setState(() => _listaConductores = dataConductores);
      }

      await _obtenerDatos();
    } catch (e) {
      _notificar("Error al inicializar", TaxiTheme.error);
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  Future<void> _obtenerDatos() async {
    setState(() => _cargando = true);
    try {
      final fIni = DateFormat('yyyy-MM-dd').format(_fechaInicio);
      final fFin = DateFormat('yyyy-MM-dd').format(_fechaFin);

      var query = _supabase.from('facturacion').select();

      if (!_esAdmin) {
        query = query.eq('creado_por', _supabase.auth.currentUser!.id);
      } else if (_conductorSeleccionado != null) {
        query = query.eq('creado_por', _conductorSeleccionado!);
      }

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

  Future<void> _seleccionarRango(BuildContext context) async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      initialDateRange: DateTimeRange(start: _fechaInicio, end: _fechaFin),
      firstDate: DateTime(2024),
      lastDate: DateTime.now(),
      initialEntryMode: DatePickerEntryMode.calendarOnly,
      helpText: 'SELECCIONA EL PERIODO',
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(primary: TaxiTheme.primaryDark),
        ),
        child: Center(child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 420), child: child!)),
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

  Future<void> _guardarFacturacion() async {
    if (!_formKey.currentState!.validate()) return;

    final monto = double.tryParse(_montoController.text.replaceAll(',', '.'));
    if (monto == null || monto <= 0) {
      _notificar("Introduce un monto válido", TaxiTheme.warning);
      return;
    }

    setState(() => _cargando = true);
    try {
      await _supabase.from('facturacion').insert({
        'monto': monto,
        'creado_por': _supabase.auth.currentUser!.id,
        'autor_nombre': _nombreAutor,
        'fecha': DateTime.now().toIso8601String().split('T')[0],
      });
      _montoController.clear();
      // ignore: use_build_context_synchronously
      FocusScope.of(context).unfocus();
      setState(() => _mostrandoFormulario = false);
      await _obtenerDatos();
      _notificar("Facturación guardada", TaxiTheme.success);
    } catch (e) {
      _notificar("Error al guardar", TaxiTheme.error);
    }
  }

  double get _totalSumado => _registros.fold(0, (sum, item) => sum + (item['monto'] ?? 0));

  void _notificar(String msg, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: color, behavior: SnackBarBehavior.floating));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // ✅ FONDO DINÁMICO: Se adapta al modo claro/oscuro
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(_mostrandoFormulario ? 'NUEVA ENTRADA' : 'FACTURACIÓN', style: TaxiTheme.tituloAppBar),
        backgroundColor: TaxiTheme.primaryDark,
        centerTitle: true,
        elevation: 0,
        leading: _mostrandoFormulario 
          ? IconButton(icon: Icon(Icons.arrow_back, color: Theme.of(context).colorScheme.onPrimary), onPressed: () => setState(() => _mostrandoFormulario = false))
          : null,
      ),
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

  Widget _buildPrincipalArea() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              if (_esAdmin) ...[
                _buildSelectorConductor(),
                const SizedBox(height: 12),
              ],
              _buildTarjetaRango(),
            ],
          ),
        ),
        if (_esAdmin) _buildResumenAdmin(),
        Expanded(child: _buildListaRegistros()),
      ],
    );
  }

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

  Widget _buildBotonGuardarAccion() {
    return Container(
      padding: EdgeInsets.only(left: 20, right: 20, bottom: MediaQuery.of(context).padding.bottom + 20, top: 20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        boxShadow: [BoxShadow(color: Theme.of(context).shadowColor.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -5))],
        borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
      ),
      child: SizedBox(
        width: double.infinity,
        height: 55,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: TaxiTheme.success,
            foregroundColor: Theme.of(context).colorScheme.onPrimary,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            elevation: 0,
          ),
          onPressed: _cargando ? null : _guardarFacturacion,
          child: _cargando 
              ? CircularProgressIndicator(color: Theme.of(context).colorScheme.onPrimary)
              : Text("CONFIRMAR Y GUARDAR", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, letterSpacing: 1, color: Theme.of(context).colorScheme.onPrimary)),
        ),
      ),
    );
  }

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

  Widget _buildSelectorConductor() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15),
      decoration: TaxiTheme.decoracionTarjeta.copyWith(color: Theme.of(context).cardColor),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          isExpanded: true,
          dropdownColor: Theme.of(context).cardColor,
          style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color),
          value: _conductorSeleccionado,
          hint: Text('Todos los conductores', style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color)),
          items: [
            DropdownMenuItem<String>(
              value: null,
              child: Text('Todos los conductores', style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color)),
            ),
            ..._listaConductores.map((c) => DropdownMenuItem<String>(
              value: c['auth_id'].toString(),
              child: Text(
                "${c['nombre']} ${c['apellido'] ?? ''}",
                style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color),
              ),
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