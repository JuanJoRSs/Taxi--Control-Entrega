import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../theme/app_theme.dart';

class Export extends StatefulWidget {
  const Export({super.key});

  @override
  State<Export> createState() => _ExportState();
}

class _ExportState extends State<Export> {
  final _supabase = Supabase.instance.client;

  bool _estaCargando = false;
  List<dynamic> _conductores = [];

  String? _conductorSelect;
  DateTime? _fechaInicio, _fechaFin;

  @override
  void initState() {
    super.initState();
    _cargarConductores();
  }

  Future<void> _cargarConductores() async {
    try {
      final data = await _supabase
          .from('conductores')
          .select('id_conductor, nombre, apellido')
          .eq('es_admin', false)
          .order('nombre');

      setState(() => _conductores = data);
    } catch (e) {
      debugPrint('Error: $e');
    }
  }

  Future<void> _procesarExportacion() async {
    if (_fechaInicio == null || _fechaFin == null) {
      _mostrarMensaje('Por favor, selecciona ambas fechas', isError: true);
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
        _mostrarMensaje('No se encontraron registros en esas fechas', isError: true);
        return;
      }

      String nombreC = "Todos";
      if (_conductorSelect != null) {
        final c = _conductores.firstWhere((e) => e['id_conductor'].toString() == _conductorSelect);
        nombreC = "${c['nombre']} ${c['apellido'] ?? ''}";
      }

      _mostrarMensaje('$nombreC: ${data.length} fichajes encontrados.');
      await _generarPDF(data, nombreC);

    } catch (e) {
      _mostrarMensaje('Error: $e', isError: true);
    } finally {
      setState(() => _estaCargando = false);
    }
  }

  Future<void> _generarPDF(List<dynamic> registros, String nombreC) async {
  final pdf = pw.Document();

  pdf.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4, 
      margin: const pw.EdgeInsets.all(32),
      build: (pw.Context context) => [
        pw.Header(level: 0, child: pw.Text("REPORTE DE FICHAJES - LM 188 - TELDE")),
        pw.SizedBox(height: 10),
        pw.Text("Conductor/es: $nombreC"),
        pw.Text("Periodo: ${DateFormat('dd/MM/yyyy').format(_fechaInicio!)} al ${DateFormat('dd/MM/yyyy').format(_fechaFin!)}"),
        pw.SizedBox(height: 20),
        pw.TableHelper.fromTextArray(
          headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
          headers: ['Fecha', 'Entrada', 'Salida'],
          data: registros.map((r) {
            // FORMATO DE FECHA ESPAÑOL (dd/MM/yyyy)
            DateTime fechaParsed = DateTime.parse(r['fecha_fichaje'].toString());
            String fechaEspanola = DateFormat('dd/MM/yyyy').format(fechaParsed);

            DateTime? entradaFull = r['hora_entrada'] != null ? DateTime.parse(r['hora_entrada']).toLocal() : null;
            DateTime? salidaFull = r['hora_salida'] != null ? DateTime.parse(r['hora_salida']).toLocal() : null;

            String txtEntrada = entradaFull != null ? DateFormat('HH:mm').format(entradaFull) : '-';
            String txtSalida = '-';

            if (salidaFull != null) {
              bool esOtroDia = entradaFull != null && (salidaFull.year != entradaFull.year || salidaFull.month != entradaFull.month || salidaFull.day != entradaFull.day);
              txtSalida = DateFormat('HH:mm').format(salidaFull) + (esOtroDia ? " (+1)" : "");
            }
            
            return [
              fechaEspanola, // Fecha en formato dd/MM/yyyy
              txtEntrada,
              txtSalida,
            ];
          }).toList(),
        ),
      ],
    ),
  );

  await Printing.layoutPdf(onLayout: (format) async => pdf.save(), name: 'Reporte_Fichajes.pdf');
}

  void _mostrarMensaje(String texto, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(texto), backgroundColor: isError ? Colors.red : Colors.green),
    );
  }

  Future<void> _seleccionarFecha(BuildContext context, bool esInicio) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2024),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() => esInicio ? _fechaInicio = picked : _fechaFin = picked);
    }
  }

  Widget _botonFecha({required String label, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Text(label, textAlign: TextAlign.center),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TaxiTheme.fondoApp,
      appBar: AppBar(
        title: const Text("EXPORTAR FICHAJES", style: TaxiTheme.tituloAppBar),
        backgroundColor: TaxiTheme.azulPrincipal,
        centerTitle: true,
      ),
      body: _estaCargando
          ? const Center(child: CircularProgressIndicator(color: TaxiTheme.azulPrincipal))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("1. Seleccionar Conductor", style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        isExpanded: true,
                        hint: const Text('Todos los conductores'),
                        value: _conductorSelect,
                        items: _conductores.map((c) {
                          return DropdownMenuItem<String>(
                            value: c['id_conductor'].toString(),
                            child: Text("${c['nombre']} ${c['apellido'] ?? ''}"),
                          );
                        }).toList(),
                        onChanged: (val) => setState(() => _conductorSelect = val),
                      ),
                    ),
                  ),
                  const SizedBox(height: 25),
                  const Text("2. Rango de Fechas", style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: _botonFecha(
                          label: _fechaInicio == null ? 'Desde' : DateFormat('dd/MM/yyyy').format(_fechaInicio!),
                          onTap: () => _seleccionarFecha(context, true),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _botonFecha(
                          label: _fechaFin == null ? 'Hasta' : DateFormat('dd/MM/yyyy').format(_fechaFin!),
                          onTap: () => _seleccionarFecha(context, false),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 50),
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: TaxiTheme.azulPrincipal,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      onPressed: _estaCargando ? null : _procesarExportacion,
                      icon: const Icon(Icons.picture_as_pdf, color: Colors.white),
                      label: const Text("GENERAR PDF", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}