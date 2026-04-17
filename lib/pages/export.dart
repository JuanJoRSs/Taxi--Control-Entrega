// Importación de librerías necesarias para la interfaz, base de datos, fechas y generación de PDF
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
  // Conexión con el cliente de Supabase
  final _supabase = Supabase.instance.client;
  
  // Variables de estado para controlar la carga, los datos y las fechas
  bool _estaCargando = false;
  List<dynamic> _conductores = [];
  String? _conductorSelect;
  DateTime? _fechaInicio, _fechaFin;

  @override
  void initState() {
    super.initState();
    // Al iniciar la pantalla, cargamos la lista de conductores para el desplegable
    _cargarConductores();
  }

  // Obtiene los nombres de los conductores desde la base de datos SQL
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

  // Lógica principal para buscar datos y preparar la exportación
  Future<void> _procesarExportacion() async {
    // Validación: Es obligatorio seleccionar un rango de fechas
    if (_fechaInicio == null || _fechaFin == null) {
      _mostrarMensaje('Por favor, selecciona el rango de fechas', isError: true);
      return;
    }

    setState(() => _estaCargando = true);

    try {
      // Formateamos las fechas al formato que entiende la base de datos (Año-Mes-Día)
      final fIni = DateFormat('yyyy-MM-dd').format(_fechaInicio!);
      final fFin = DateFormat('yyyy-MM-dd').format(_fechaFin!);

      // Preparamos la consulta a la tabla de fichajes
      var query = _supabase.from('fichajes').select('*');

      // Si se seleccionó un conductor específico, filtramos por su ID
      if (_conductorSelect != null) {
        query = query.eq('id_conductor', int.parse(_conductorSelect!));
      }

      // Ejecutamos la consulta filtrando por el rango de fechas seleccionado
      final List<dynamic> data = await query
          .gte('fecha_fichaje', fIni)
          .lte('fecha_fichaje', fFin)
          .order('id_conductor')
          .order('fecha_fichaje');

      // Si no hay datos, avisamos al usuario y detenemos el proceso
      if (data.isEmpty) {
        _mostrarMensaje('No hay registros en esas fechas', isError: true);
        return;
      }

      // Determinamos el nombre del conductor para el título del reporte
      String nombreC = "Todos";
      if (_conductorSelect != null) {
        final c = _conductores.firstWhere(
          (e) => e['id_conductor'].toString() == _conductorSelect,
        );
        nombreC = "${c['nombre']} ${c['apellido'] ?? ''}";
      }

      bool esTodos = _conductorSelect == null;

      _mostrarMensaje('Generando reporte para $nombreC...');
      
      // Llamamos a la función que construye y muestra el archivo PDF
      await _generarPDF(data, nombreC, esTodos: esTodos);

    } catch (e) {
      _mostrarMensaje('Error inesperado: $e', isError: true);
    } finally {
      setState(() => _estaCargando = false);
    }
  }

  // Función que construye la estructura visual del documento PDF
  Future<void> _generarPDF(List<dynamic> registros, String nombreC, {bool esTodos = false}) async {
    final pdf = pw.Document();

    // Definimos los encabezados de la tabla según si es un reporte general o individual
    final headers = esTodos
        ? ['Conductor', 'Fecha', 'Entrada', 'Salida']
        : ['Fecha', 'Entrada', 'Salida'];

    // Añadimos una página al documento
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(24),
        build: (pw.Context context) => [
          // Título principal del documento
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

          // Información del conductor y periodo seleccionado
          if (!esTodos)
            pw.Text("Conductor: $nombreC", style: const pw.TextStyle(fontSize: 10)),
          pw.Text(
            "Periodo: ${DateFormat('dd/MM/yyyy').format(_fechaInicio!)} - ${DateFormat('dd/MM/yyyy').format(_fechaFin!)}",
            style: const pw.TextStyle(fontSize: 10),
          ),
          pw.SizedBox(height: 15),

          // Creación de la tabla de datos
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
              // Fila de encabezado con fondo oscuro y texto blanco
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

              // Generación de las filas de datos recorriendo los registros de la base de datos
              ...registros.asMap().entries.map((entry) {
                int index = entry.key;
                var r = entry.value;

                // Formateo de fecha y horas para el PDF
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

                // Si es el reporte de todos, buscamos el nombre del conductor para la primera celda
                if (esTodos) {
                  final conductor = _conductores.firstWhere(
                    (c) => c['id_conductor'] == r['id_conductor'],
                    orElse: () => {'nombre': 'Desconocido', 'apellido': ''},
                  );
                  row.add("${conductor['nombre']} ${conductor['apellido'] ?? ''}");
                }

                row.addAll([fechaEspanola, txtEntrada, txtSalida]);

                // Retornamos la fila con colores alternos para facilitar la lectura
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

          // Pie de página con la fecha y hora exacta de generación
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

    // Muestra el diálogo de impresión o guardado del sistema
    await Printing.layoutPdf(
      onLayout: (format) async => pdf.save(),
      name: 'Reporte_TaxiControl.pdf',
    );
  }

  // Pequeño componente para dar formato a las celdas de la tabla del PDF
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

  // Muestra una barra de notificación en la parte inferior de la pantalla
  void _mostrarMensaje(String texto, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(texto),
        backgroundColor: isError ? TaxiTheme.error : TaxiTheme.success,
      ),
    );
  }

  // Abre el calendario del sistema para elegir fechas de inicio y fin
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

  // Título visual de cada sección con color adaptativo al tema oscuro/claro
  Widget _seccionTitulo(String titulo) => Text(
    titulo, 
    style: TextStyle(
      fontSize: 13, 
      fontWeight: FontWeight.w800, 
      color: Theme.of(context).textTheme.bodyLarge?.color, 
      letterSpacing: 1.1
    )
  );

  // Botón personalizado para la selección de fechas
  Widget _botonFechaPro({required String label, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      child: Container(
        height: 55,
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
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.calendar_today_outlined, size: 16, color: Theme.of(context).textTheme.bodyLarge?.color),
            const SizedBox(width: 10),
            Text(label, style: TextStyle(fontWeight: FontWeight.w600, color: Theme.of(context).textTheme.bodyLarge?.color)),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
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
                  // Contenedor del desplegable de conductores
                  Container(
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
                  // Fila con los dos botones de selección de fecha
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
                  // Botón final para ejecutar la exportación
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