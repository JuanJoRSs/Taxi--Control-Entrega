import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../theme/app_theme.dart'; // <--- Importamos tus nuevos tokens premium

class Export extends StatefulWidget {
  const Export({super.key});

  @override
  State<Export> createState() => _ExportState();
}

class _ExportState extends State<Export> {
  // VARIABLES
  final _supabase = Supabase.instance.client; // Conexión Supabase
  bool _estaCargando = false; // Estado de carga
  List<dynamic> _conductores = []; // Lista para el desplegable
  String? _conductorSelect; // ID del conductor elegido
  DateTime? _fechaInicio, _fechaFin; // Rango de fechas

  @override
  void initState() {
    super.initState();
    _cargarConductores(); // Al iniciar, cargamos la lista de empleados
  }

  // LÓGICA: Cargar conductores para el filtro
  Future<void> _cargarConductores() async {
    try {
      final data = await _supabase
          .from('conductores')
          .select('id_conductor, nombre, apellido')
          .eq('es_admin', false)
          .order('nombre');
      setState(() => _conductores = data);
    } catch (e) {
      debugPrint('Error cargando lista: $e');
    }
  }

  // LÓGICA: Procesar y filtrar datos
  Future<void> _procesarExportacion() async {
    if (_fechaInicio == null || _fechaFin == null) {
      _mostrarMensaje('Por favor, selecciona el rango de fechas', isError: true);
      return;
    }

    setState(() => _estaCargando = true);

    try {
      final fIni = DateFormat('yyyy-MM-dd').format(_fechaInicio!);
      final fFin = DateFormat('yyyy-MM-dd').format(_fechaFin!);

      var query = _supabase.from('fichajes').select('*');

      if (_conductorSelect != null) {
        query = query.eq('id_conductor', int.parse(_conductorSelect!));
      }

      final List<dynamic> data = await query
          .gte('fecha_fichaje', fIni)
          .lte('fecha_fichaje', fFin)
          .order('fecha_fichaje');

      if (data.isEmpty) {
        _mostrarMensaje('No hay registros en esas fechas', isError: true);
        return;
      }

      String nombreC = "Todos";
      if (_conductorSelect != null) {
        final c = _conductores.firstWhere((e) => e['id_conductor'].toString() == _conductorSelect);
        nombreC = "${c['nombre']} ${c['apellido'] ?? ''}";
      }

      _mostrarMensaje('Generando reporte para $nombreC...');
      await _generarPDF(data, nombreC);

    } catch (e) {
      _mostrarMensaje('Error inesperado: $e', isError: true);
    } finally {
      setState(() => _estaCargando = false);
    }
  }

  // LÓGICA: Generación del documento PDF profesional
  Future<void> _generarPDF(List<dynamic> registros, String nombreC) async {
  final pdf = pw.Document();

  pdf.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4, 
      margin: const pw.EdgeInsets.all(32),
      build: (pw.Context context) => [
        pw.Header(level: 0, child: pw.Text("REPORTE DE FICHAJES - TAXI CONTROL")),
        pw.SizedBox(height: 10),
        pw.Text("Conductor: $nombreC"),
        pw.Text("Periodo: ${DateFormat('dd/MM/yyyy').format(_fechaInicio!)} al ${DateFormat('dd/MM/yyyy').format(_fechaFin!)}"),
        pw.SizedBox(height: 20),
        pw.TableHelper.fromTextArray(
          headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white),
          headerDecoration: const pw.BoxDecoration(color: PdfColor.fromInt(0xFF1A2B4C)), // Azul noche en el PDF
          headers: ['Fecha', 'Entrada', 'Salida'],
          data: registros.map((r) {
            DateTime fechaParsed = DateTime.parse(r['fecha_fichaje'].toString());
            String fechaEspanola = DateFormat('dd/MM/yyyy').format(fechaParsed);

            DateTime? entradaFull = r['hora_entrada'] != null ? DateTime.parse(r['hora_entrada']).toLocal() : null;
            DateTime? salidaFull = r['hora_salida'] != null ? DateTime.parse(r['hora_salida']).toLocal() : null;

            String txtEntrada = entradaFull != null ? DateFormat('HH:mm').format(entradaFull) : '-';
            String txtSalida = salidaFull != null ? DateFormat('HH:mm').format(salidaFull) : '-';
            
            return [fechaEspanola, txtEntrada, txtSalida];
          }).toList(),
        ),
      ],
    ),
  );

  await Printing.layoutPdf(onLayout: (format) async => pdf.save(), name: 'Reporte_TaxiControl.pdf');
}

  // DISEÑO: Elementos visuales auxiliares
  void _mostrarMensaje(String texto, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(texto), backgroundColor: isError ? TaxiTheme.error : TaxiTheme.success),
    );
  }

  Future<void> _seleccionarFecha(BuildContext context, bool esInicio) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2024),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(primary: TaxiTheme.primaryDark), // Calendario en azul noche
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => esInicio ? _fechaInicio = picked : _fechaFin = picked);
    }
  }

  Widget _seccionTitulo(String titulo) => Text(
    titulo, 
    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: TaxiTheme.primaryDark, letterSpacing: 1.1)
  );

  Widget _botonFechaPro({required String label, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      child: Container(
        height: 55,
        decoration: TaxiTheme.decoracionTarjeta,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.calendar_today_outlined, size: 16, color: TaxiTheme.primaryDark),
            const SizedBox(width: 10),
            Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  // DISEÑO: Construcción de la interfaz
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TaxiTheme.backgroundLight,
      appBar: AppBar(
        title: const Text("EXPORTAR INFORMES", style: TaxiTheme.tituloAppBar),
        backgroundColor: TaxiTheme.primaryDark,
        centerTitle: true,
        elevation: 0,
      ),
      body: _estaCargando
          ? const Center(child: CircularProgressIndicator(color: TaxiTheme.accentGold))
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 30),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _seccionTitulo("1. SELECCIONAR CONDUCTOR"),
                  const SizedBox(height: 12),
                  Container(
                    decoration: TaxiTheme.decoracionTarjeta,
                    padding: const EdgeInsets.symmetric(horizontal: 15),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        isExpanded: true,
                        hint: const Text('Todos los conductores'),
                        value: _conductorSelect,
                        items: _conductores.map((c) => DropdownMenuItem<String>(
                          value: c['id_conductor'].toString(),
                          child: Text("${c['nombre']} ${c['apellido'] ?? ''}"),
                        )).toList(),
                        onChanged: (val) => setState(() => _conductorSelect = val),
                      ),
                    ),
                  ),
                  const SizedBox(height: 35),
                  _seccionTitulo("2. RANGO DEL PERIODO"),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(child: _botonFechaPro(
                        label: _fechaInicio == null ? 'Fecha Inicio' : DateFormat('dd/MM/yyyy').format(_fechaInicio!),
                        onTap: () => _seleccionarFecha(context, true),
                      )),
                      const SizedBox(width: 15),
                      Expanded(child: _botonFechaPro(
                        label: _fechaFin == null ? 'Fecha Fin' : DateFormat('dd/MM/yyyy').format(_fechaFin!),
                        onTap: () => _seleccionarFecha(context, false),
                      )),
                    ],
                  ),
                  const SizedBox(height: 60),
                  // Botón de acción principal en color Oro/Ámbar
                  SizedBox(
                    width: double.infinity,
                    height: 58,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: TaxiTheme.accentGold,
                        foregroundColor: TaxiTheme.primaryDark,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 4,
                      ),
                      onPressed: _estaCargando ? null : _procesarExportacion,
                      icon: const Icon(Icons.picture_as_pdf),
                      label: const Text("DESCARGAR REPORTE PDF", style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 0.8)),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}