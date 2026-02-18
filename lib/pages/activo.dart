import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../theme/app_theme.dart'; // <--- Tus tokens

class Activo extends StatefulWidget {
  const Activo({super.key});

  @override
  State<Activo> createState() => _ActivoState();
}

class _ActivoState extends State<Activo> {
  final _supabase = Supabase.instance.client;
  List<dynamic> _activos = [];
  bool _cargando = true;

  @override
  void initState() {
    super.initState();
    _obtenerActivos();
  }

  Future<void> _obtenerActivos() async {
    try {
      setState(() => _cargando = true);

      // Relación con tabla conductores para traer el nombre
      final data = await _supabase
          .from('fichajes')
          .select('*, conductores(nombre)')
          .isFilter('hora_salida', null);

      if (mounted) {
        setState(() {
          _activos = data;
          _cargando = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _cargando = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: TaxiTheme.alerta,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TaxiTheme.fondoApp, // TOKEN: Fondo off-white
      appBar: AppBar(
        title: const Text(
          'CONDUCTORES EN TURNO',
          style: TaxiTheme.tituloAppBar,
        ),
        centerTitle: true,
        backgroundColor: TaxiTheme.azulPrincipal, // TOKEN: Azul unificado
        elevation: 0,
        iconTheme: const IconThemeData(color: TaxiTheme.blancoPuro),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _obtenerActivos,
            tooltip: 'Refrescar',
          ),
        ],
      ),
      body: _cargando
          ? const Center(
              child: CircularProgressIndicator(color: TaxiTheme.azulPrincipal),
            )
          : _activos.isEmpty
          ? Center(
              child: Text(
                'No hay conductores activos.',
                style: TaxiTheme.subtitulo,
              ),
            )
          : RefreshIndicator(
              color: TaxiTheme.azulPrincipal,
              onRefresh: _obtenerActivos,
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _activos.length,
                itemBuilder: (context, index) {
                  final fichaje = _activos[index];
                  final nombreConductor = fichaje['conductores'] != null
                      ? fichaje['conductores']['nombre']
                      : 'Desconocido';

                  // Formateo rápido de hora
                  String horaEntrada = fichaje['hora_entrada'] ?? '';
                  if (horaEntrada.length > 16) {
                    horaEntrada = horaEntrada.substring(11, 16);
                  }

                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration:
                        TaxiTheme.decoracionTarjeta, // TOKEN: Tarjeta unificada
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      leading: CircleAvatar(
                        backgroundColor: TaxiTheme.exito.withOpacity(0.1),
                        child: const Icon(
                          Icons.local_taxi,
                          color: TaxiTheme.exito,
                          size: 20,
                        ),
                      ),
                      title: Text(
                        nombreConductor,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: TaxiTheme.grisTextoPrincipal,
                        ),
                      ),
                      subtitle: Row(
                        children: [
                          const Icon(
                            Icons.access_time,
                            size: 14,
                            color: TaxiTheme.grisTextoSecundario,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Entrada: $horaEntrada',
                            style: TaxiTheme.subtitulo,
                          ),
                        ],
                      ),
                      trailing: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: TaxiTheme.exito.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'ACTIVO',
                          style: TextStyle(
                            color: TaxiTheme.exito,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
    );
  }
}
