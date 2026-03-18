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
          .order('nombre');

      setState(() => _conductores = data);
    } catch (e) {
      debugPrint('Error cargando lista: $e');
    }
  }

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
          .order('id_conductor')
          .order('fecha_fichaje');

      if (data.isEmpty) {
        _mostrarMensaje('No hay registros en esas fechas', isError: true);
        return;
      }

      String nombreC = "Todos";
      if (_conductorSelect != null) {
        final c = _conductores.firstWhere(
          (e) => e['id_conductor'].toString() == _conductorSelect,
        );
        nombreC = "${c['nombre']} ${c['apellido'] ?? ''}";
      }

      bool esTodos = _conductorSelect == null;

      _mostrarMensaje('Generando reporte para $nombreC...');
      await _generarPDF(data, nombreC, esTodos: esTodos);

    } catch (e) {
      _mostrarMensaje('Error inesperado: $e', isError: true);
    } finally {
      setState(() => _estaCargando = false);
    }
  }

  /// 🔥 PDF DINÁMICO
  Future<void> _generarPDF(List<dynamic> registros, String nombreC, {bool esTodos = false}) async {
    final pdf = pw.Document();

    final headers = esTodos
        ? ['Conductor', 'Fecha', 'Entrada', 'Salida']
        : ['Fecha', 'Entrada', 'Salida'];

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(24),
        build: (pw.Context context) => [

          pw.Center(
            child: pw.Text(
              esTodos ? "REPORTE GENERAL DE FICHAJES" : "REPORTE DE FICHAJES",
              style: pw.TextStyle(
                fontSize: 18,
                fontWeight: pw.FontWeight.bold,
                color: PdfColor.fromInt(0xFF1A2B4C),
              ),
            ),
          ),

          pw.SizedBox(height: 5),

          pw.Center(
            child: pw.Text(
              "Taxi Control",
              style: pw.TextStyle(fontSize: 12, color: PdfColors.grey700),
            ),
          ),

          pw.Divider(thickness: 1),
          pw.SizedBox(height: 10),

          if (!esTodos)
            pw.Text("Conductor: $nombreC", style: const pw.TextStyle(fontSize: 10)),

          pw.Text(
            "Periodo: ${DateFormat('dd/MM/yyyy').format(_fechaInicio!)} - ${DateFormat('dd/MM/yyyy').format(_fechaFin!)}",
            style: const pw.TextStyle(fontSize: 10),
          ),

          pw.SizedBox(height: 15),

          pw.Table(
            border: pw.TableBorder.all(color: PdfColors.grey400, width: 0.5),
            columnWidths: esTodos
                ? {
                    0: const pw.FlexColumnWidth(2),
                    1: const pw.FlexColumnWidth(2),
                    2: const pw.FlexColumnWidth(1.5),
                    3: const pw.FlexColumnWidth(1.5),
                  }
                : {
                    0: const pw.FlexColumnWidth(2),
                    1: const pw.FlexColumnWidth(1.5),
                    2: const pw.FlexColumnWidth(1.5),
                  },
            children: [

              /// HEADER
              pw.TableRow(
                decoration: const pw.BoxDecoration(
                  color: PdfColor.fromInt(0xFF1A2B4C),
                ),
                children: headers.map((header) {
                  return pw.Padding(
                    padding: const pw.EdgeInsets.all(8),
                    child: pw.Text(
                      header,
                      style: pw.TextStyle(
                        color: PdfColors.white,
                        fontSize: 10,
                        fontWeight: pw.FontWeight.bold,
                      ),
                      textAlign: pw.TextAlign.center,
                    ),
                  );
                }).toList(),
              ),

              /// FILAS
              ...registros.asMap().entries.map((entry) {
                int index = entry.key;
                var r = entry.value;

                DateTime fechaParsed = DateTime.parse(r['fecha_fichaje'].toString());
                String fechaEspanola = DateFormat('dd/MM/yyyy').format(fechaParsed);

                DateTime? entradaFull = r['hora_entrada'] != null
                    ? DateTime.parse(r['hora_entrada']).toLocal()
                    : null;

                DateTime? salidaFull = r['hora_salida'] != null
                    ? DateTime.parse(r['hora_salida']).toLocal()
                    : null;

                String txtEntrada = entradaFull != null
                    ? DateFormat('HH:mm').format(entradaFull)
                    : '-';

                String txtSalida = salidaFull != null
                    ? DateFormat('HH:mm').format(salidaFull)
                    : '-';

                List<String> row = [];

                if (esTodos) {
                  final conductor = _conductores.firstWhere(
                    (c) => c['id_conductor'] == r['id_conductor'],
                    orElse: () => {'nombre': 'Desconocido', 'apellido': ''},
                  );

                  row.add("${conductor['nombre']} ${conductor['apellido'] ?? ''}");
                }

                row.addAll([
                  fechaEspanola,
                  txtEntrada,
                  txtSalida,
                ]);

                return pw.TableRow(
                  decoration: pw.BoxDecoration(
                    color: index % 2 == 0 ? PdfColors.grey100 : PdfColors.white,
                  ),
                  children: row.map((cell) => _cell(cell)).toList(),
                );
              }),
            ],
          ),

          pw.SizedBox(height: 20),

          pw.Align(
            alignment: pw.Alignment.centerRight,
            child: pw.Text(
              "Generado el ${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now())}",
              style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
            ),
          ),
        ],
      ),
    );

    await Printing.layoutPdf(
      onLayout: (format) async => pdf.save(),
      name: 'Reporte_TaxiControl.pdf',
    );
  }

  pw.Widget _cell(String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(8),
      child: pw.Text(
        text,
        style: const pw.TextStyle(fontSize: 10),
        textAlign: pw.TextAlign.center,
      ),
    );
  }

  void _mostrarMensaje(String texto, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(texto),
        backgroundColor: isError ? TaxiTheme.error : TaxiTheme.success,
      ),
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
            colorScheme: const ColorScheme.light(primary: TaxiTheme.primaryDark),
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
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w800,
          color: TaxiTheme.primaryDark,
          letterSpacing: 1.1,
        ),
      );

  Widget _botonFechaPro({required String label, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      child: Container(
        height: 55,
        decoration: TaxiTheme.decoracionTarjeta.copyWith(
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
            const Icon(Icons.calendar_today_outlined, size: 16, color: TaxiTheme.primaryDark),
            const SizedBox(width: 10),
            Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TaxiTheme.backgroundLight,
      appBar: AppBar(
        title: const Text("EXPORTAR INFORMES", style: TaxiTheme.tituloAppBar),
        backgroundColor: TaxiTheme.primaryDark,
        centerTitle: true,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
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
                    decoration: TaxiTheme.decoracionTarjeta.copyWith(
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
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
                  SizedBox(
                    width: double.infinity,
                    height: 58,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: TaxiTheme.accentGold,
                        foregroundColor: TaxiTheme.primaryDark,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 4,
                        shadowColor: Colors.black.withOpacity(0.3),
                      ),
                      onPressed: _estaCargando ? null : _procesarExportacion,
                      icon: const Icon(Icons.picture_as_pdf),
                      label: const Text(
                        "DESCARGAR REPORTE PDF",
                        style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 0.8),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}