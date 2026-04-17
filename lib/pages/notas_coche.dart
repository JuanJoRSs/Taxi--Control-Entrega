import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../theme/app_theme.dart';

class NotasCoche extends StatefulWidget {
  const NotasCoche({super.key});

  @override
  State<NotasCoche> createState() => _NotasCoche();
}

class _NotasCoche extends State<NotasCoche> {
  final _supabase = Supabase.instance.client;
  bool _enviando = false;
  String _nombreAutor = "Admin";

  @override
  void initState() {
    super.initState();
    _cargarDatosUsuario();
  }

  Future<void> _cargarDatosUsuario() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return;

      final data = await _supabase
          .from('conductores')
          .select('nombre, apellido')
          .eq('auth_id', userId)
          .single();

      if (mounted) {
        setState(() => _nombreAutor = "${data['nombre']} ${data['apellido']}");
      }
    } catch (e) {
      debugPrint(e.toString());
    }
  }

  void _notificar(String msg, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: color, duration: const Duration(seconds: 2)),
    );
  }

  Future<void> _publicarNota(String cat, String desc) async {
    if (desc.trim().isEmpty) return;
    setState(() => _enviando = true);
    try {
      await _supabase.from('notas_coche').insert({
        'categoria': cat,
        'descripcion': desc.trim(),
        'creado_por': _supabase.auth.currentUser!.id, // Seguridad
        'autor_nombre': _nombreAutor, // Visual
      });
      if (mounted) Navigator.pop(context);
    } catch (e) {
      _notificar("Error: $e", TaxiTheme.error);
    } finally {
      if (mounted) setState(() => _enviando = false);
    }
  }

  void _mostrarDialogoNuevaNota() {
    final controller = TextEditingController();
    String cat = 'Avería';
    final opciones = ['Avería', 'Mantenimiento', 'Efectivo', 'Limpieza', 'Otros'];

    showDialog(
      context: context,
      barrierDismissible: !_enviando,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          // ✅ FONDO DEL DIÁLOGO DINÁMICO
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(TaxiTheme.radioTarjeta)),
          title: const Text('NUEVA ANOTACIÓN', style: TextStyle(color: TaxiTheme.primaryDark, fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                value: cat,
                decoration: InputDecoration(
                  filled: true,
                  // ✅ FONDO DEL SELECTOR DINÁMICO
                  fillColor: Theme.of(context).cardColor,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                ),
                // ✅ TEXTO DEL SELECTOR DINÁMICO
                items: opciones.map((e) => DropdownMenuItem(value: e, child: Text(e, style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color)))).toList(),
                onChanged: (val) => setDialogState(() => cat = val!),
              ),
              const SizedBox(height: 15),
              TextField(
                controller: controller,
                maxLines: 3,
                // ✅ TEXTO DEL INPUT DINÁMICO
                style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color),
                decoration: InputDecoration(
                  hintText: 'Escribe aquí...',
                  hintStyle: const TextStyle(color: TaxiTheme.textSecondary),
                  filled: true,
                  // ✅ FONDO DEL INPUT DINÁMICO
                  fillColor: Theme.of(context).cardColor,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: _enviando ? null : () => Navigator.pop(context),
              child: const Text('CANCELAR', style: TextStyle(color: TaxiTheme.textSecondary)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: TaxiTheme.primaryDark, foregroundColor: TaxiTheme.surfaceWhite),
              onPressed: _enviando ? null : () => _publicarNota(cat, controller.text),
              child: _enviando 
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Text('PUBLICAR'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // ✅ 1. FONDO PANTALLA DINÁMICO
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('ANOTACIONES DEL VEHICULO', style: TaxiTheme.tituloAppBar),
        centerTitle: true,
        backgroundColor: TaxiTheme.primaryDark,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _supabase
            .from('notas_coche')
            .stream(primaryKey: ['id'])
            .order('created_at', ascending: false),
        builder: (context, snapshot) {
          if (snapshot.hasError) return const Center(child: Text('Error de conexión'));
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator(color: TaxiTheme.accentGold));
          
          final notas = snapshot.data!;

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: notas.length,
            itemBuilder: (context, index) {
              final nota = notas[index];
              final color = _colorPorCategoria(nota['categoria']);
              final idNota = nota['id'].toString();

              return Dismissible(
                key: Key(idNota),
                direction: DismissDirection.endToStart,
                onDismissed: (_) async => await _supabase.from('notas_coche').delete().eq('id', idNota),
                background: Container(
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 20),
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: TaxiTheme.error,
                    borderRadius: BorderRadius.circular(TaxiTheme.radioTarjeta),
                  ),
                  child: const Icon(Icons.delete_outline, color: Colors.white, size: 30),
                ),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  // ✅ 2. FONDO TARJETA DINÁMICO (manteniendo tu borde izquierdo)
                  decoration: TaxiTheme.decoracionTarjeta.copyWith(
                    color: Theme.of(context).cardColor,
                    border: Border(left: BorderSide(color: color, width: 6)),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(16),
                    title: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(nota['categoria'].toUpperCase(),
                          style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12),
                        ),
                        Text(nota['autor_nombre'] ?? "Admin", 
                          style: const TextStyle(fontSize: 11, color: TaxiTheme.textSecondary, fontStyle: FontStyle.italic)),
                      ],
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 8),
                      // ✅ 3. TEXTO DESCRIPCIÓN DINÁMICO
                      child: Text(nota['descripcion'],
                        style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color, fontSize: 15),
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: TaxiTheme.primaryDark,
        onPressed: _mostrarDialogoNuevaNota,
        child: const Icon(Icons.add_comment, color: TaxiTheme.surfaceWhite),
      ),
    );
  }

  Color _colorPorCategoria(String cat) {
    switch (cat) {
      case 'Avería': return TaxiTheme.error;
      case 'Mantenimiento': return Colors.blueAccent;
      case 'Efectivo': return TaxiTheme.success;
      case 'Limpieza': return TaxiTheme.accentGold;
      default: return TaxiTheme.primaryDark;
    }
  }
}