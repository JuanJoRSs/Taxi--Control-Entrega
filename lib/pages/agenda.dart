import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Para copiar al portapapeles
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/foundation.dart' show kIsWeb; 
import '../theme/app_theme.dart';

class AgendaContactos extends StatefulWidget {
  const AgendaContactos({super.key});

  @override
  State<AgendaContactos> createState() => _AgendaContactosState();
}

class _AgendaContactosState extends State<AgendaContactos> {
  final _supabase = Supabase.instance.client;
  final _nombreController = TextEditingController();
  final _telefonoController = TextEditingController(); // Este controla el campo "numero"
  final _formKey = GlobalKey<FormState>();

  bool _cargando = true;
  bool _mostrandoFormulario = false;
  List<dynamic> _contactos = [];

  // Detectar si es ordenador (Web) para copiar en lugar de llamar
  bool get _esOrdenador => kIsWeb;

  @override
  void initState() {
    super.initState();
    _obtenerContactos();
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _telefonoController.dispose();
    super.dispose();
  }

  // LEER: Corregido para usar la columna 'numero'
  Future<void> _obtenerContactos() async {
    setState(() => _cargando = true);
    try {
      final data = await _supabase.from('agenda').select().order('nombre');
      setState(() => _contactos = data);
    } catch (e) {
      _notificar("Error al cargar agenda", TaxiTheme.error);
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  // ACCIÓN: Llamar o Copiar
  Future<void> _gestionarAccion(String numero) async {
    if (_esOrdenador) {
      await Clipboard.setData(ClipboardData(text: numero));
      _notificar("Número copiado al portapapeles", TaxiTheme.success);
    } else {
      final Uri launchUri = Uri(scheme: 'tel', path: numero);
      if (await canLaunchUrl(launchUri)) {
        await launchUrl(launchUri);
      } else {
        _notificar("No se puede realizar la llamada", TaxiTheme.error);
      }
    }
  }

  // GUARDAR: Corregido con la clave 'numero' para tu tabla
  Future<void> _guardarContacto() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _cargando = true);
    try {
      await _supabase.from('agenda').insert({
        'nombre': _nombreController.text.trim(),
        'numero': _telefonoController.text.trim(), // <--- COINCIDE CON TU TABLA
      });
      
      _nombreController.clear();
      _telefonoController.clear();
      setState(() => _mostrandoFormulario = false);
      await _obtenerContactos();
      _notificar("Contacto guardado correctamente", TaxiTheme.success);
    } catch (e) {
      // Si falla, mostramos el error exacto para debugear
      _notificar("Error: ${e.toString()}", TaxiTheme.error);
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  void _notificar(String msg, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg), 
      backgroundColor: color,
      behavior: SnackBarBehavior.floating,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TaxiTheme.backgroundLight,
      appBar: AppBar(
        title: const Text('AGENDA DE CONTACTOS', style: TaxiTheme.tituloAppBar),
        backgroundColor: TaxiTheme.primaryDark,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          if (_mostrandoFormulario)
            IconButton(
              icon: const Icon(Icons.close), 
              onPressed: () => setState(() => _mostrandoFormulario = false)
            )
        ],
      ),
      body: _mostrandoFormulario ? _buildFormulario() : _buildLista(),
      floatingActionButton: _mostrandoFormulario 
        ? null 
        : FloatingActionButton(
            backgroundColor: TaxiTheme.accentGold,
            onPressed: () => setState(() => _mostrandoFormulario = true),
            child: const Icon(Icons.person_add, color: TaxiTheme.primaryDark),
          ),
    );
  }

  Widget _buildLista() {
    if (_cargando) return const Center(child: CircularProgressIndicator(color: TaxiTheme.primaryDark));
    if (_contactos.isEmpty) return const Center(child: Text("No hay contactos guardados"));

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: _contactos.length,
      itemBuilder: (context, index) {
        final c = _contactos[index];
        final numFull = c['numero'].toString(); // Accedemos a 'numero'

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: TaxiTheme.decoracionTarjeta,
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            leading: CircleAvatar(
              backgroundColor: TaxiTheme.primaryDark.withOpacity(0.1),
              child: const Icon(Icons.person, color: TaxiTheme.primaryDark),
            ),
            title: Text(
              c['nombre'].toString().toUpperCase(), 
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 1)
            ),
            subtitle: Text(
              numFull, 
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: TaxiTheme.success)
            ),
            trailing: IconButton(
              icon: Icon(_esOrdenador ? Icons.copy_rounded : Icons.phone_forwarded),
              color: TaxiTheme.accentGold,
              onPressed: () => _gestionarAccion(numFull),
            ),
          ),
        );
      },
    );
  }

  Widget _buildFormulario() {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(25),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("NUEVO CONTACTO", style: TextStyle(fontWeight: FontWeight.bold, color: TaxiTheme.primaryDark)),
                  const SizedBox(height: 20),
                  _buildTextField(_nombreController, "Nombre completo", Icons.badge),
                  const SizedBox(height: 20),
                  _buildTextField(_telefonoController, "Número de teléfono", Icons.phone, keyboard: TextInputType.phone),
                  const SizedBox(height: 10),
                  const Text(
                    "Se guardará en la agenda común de la flota.",
                    style: TextStyle(fontSize: 12, color: TaxiTheme.textSecondary, fontStyle: FontStyle.italic),
                  ),
                ],
              ),
            ),
          ),
          _buildBotonGuardarAbajo(),
        ],
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String hint, IconData icon, {TextInputType keyboard = TextInputType.text}) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboard,
      style: const TextStyle(fontWeight: FontWeight.bold),
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: Icon(icon, color: TaxiTheme.primaryDark),
        filled: true,
        fillColor: TaxiTheme.surfaceWhite,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.withOpacity(0.1))),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: TaxiTheme.accentGold)),
      ),
      validator: (v) => v!.isEmpty ? "Este campo no puede estar vacío" : null,
    );
  }

  Widget _buildBotonGuardarAbajo() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: TaxiTheme.surfaceWhite,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -5))],
      ),
      child: SizedBox(
        width: double.infinity,
        height: 55,
        child: ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: TaxiTheme.success, 
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
          ),
          onPressed: _cargando ? null : _guardarContacto,
          icon: _cargando 
            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
            : const Icon(Icons.save, color: Colors.white),
          label: Text(
            _cargando ? "PROCESANDO..." : "GUARDAR EN AGENDA", 
            style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 16)
          ),
        ),
      ),
    );
  }
}