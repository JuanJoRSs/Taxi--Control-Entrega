import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../theme/app_theme.dart'; // <--- Importamos tus tokens premium

class Activo extends StatefulWidget {
  const Activo({super.key});

  @override
  State<Activo> createState() => _ActivoState();
}

class _ActivoState extends State<Activo> {
  // VARIABLES
  final _supabase = Supabase.instance.client; // Conexión a la base de datos
  List<dynamic> _activos = []; // Lista para guardar los conductores en turno
  bool _cargando = true; // Control del círculo de carga

  @override
  void initState() {
    super.initState();
    // Nada más entrar, buscamos quién está trabajando
    _obtenerActivos();
  }

  // LÓGICA: Consultar Supabase
  // Obtenemos los conductores que han iniciado turno pero aún no han salido
  Future<void> _obtenerActivos() async {
    try {
      setState(() => _cargando = true);

      // Relación con tabla conductores para traer el nombre del taxista
      // Filtramos por aquellos que no tengan hora de salida registrada
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
        // Notificación de error con el nuevo color corporativo
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error de sincronización: $e'),
            backgroundColor: TaxiTheme.error, 
          ),
        );
      }
    }
  }

  // DISEÑO: Dibujar la pantalla
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TaxiTheme.backgroundLight, // FONDO: Gris perla ejecutivo
      appBar: AppBar(
        title: const Text(
          'ESTADO DE FLOTA', // Título más profesional
          style: TaxiTheme.tituloAppBar,
        ),
        centerTitle: true,
        backgroundColor: TaxiTheme.primaryDark, // AZUL: Noche profundo
        elevation: 0,
        iconTheme: const IconThemeData(color: TaxiTheme.surfaceWhite),
        actions: [
          IconButton(
            icon: const Icon(Icons.sync), // Icono de sincronización
            onPressed: _obtenerActivos,
            tooltip: 'Refrescar estado',
          ),
        ],
      ),
      body: _cargando
          ? const Center(
              child: CircularProgressIndicator(color: TaxiTheme.accentGold), // CARGA: En dorado
            )
          : _activos.isEmpty
          ? const Center(
              child: Text(
                'No hay conductores operativos ahora mismo.',
                style: TextStyle(color: TaxiTheme.textSecondary),
              ),
            )
          : RefreshIndicator(
              color: TaxiTheme.primaryDark,
              onRefresh: _obtenerActivos,
              child: ListView.builder(
                padding: const EdgeInsets.all(20),
                itemCount: _activos.length,
                itemBuilder: (context, index) {
                  final fichaje = _activos[index];
                  final nombre = fichaje['conductores']?['nombre'] ?? 'Sin Identificar';

                  // Formateo de hora profesional (HH:mm)
                  String hora = fichaje['hora_entrada']?.toString().substring(11, 16) ?? '--:--';

                  return Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: TaxiTheme.decoracionTarjeta, // SOMBRA: Neumorfismo suave
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(15),
                      leading: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: TaxiTheme.success.withOpacity(0.1), 
                          shape: BoxShape.circle
                        ),
                        child: const Icon(
                          Icons.directions_car_filled, // Icono de taxi moderno
                          color: TaxiTheme.success, 
                        ),
                      ),
                      title: Text(
                        nombre.toUpperCase(), 
                        style: const TextStyle(
                          fontWeight: FontWeight.w800, 
                          color: TaxiTheme.primaryDark,
                          letterSpacing: 0.5
                        )
                      ),
                      subtitle: Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Row(
                          children: [
                            const Icon(Icons.access_time_filled, size: 14, color: TaxiTheme.textSecondary),
                            const SizedBox(width: 6),
                            Text(
                              'En servicio desde las $hora', 
                              style: const TextStyle(color: TaxiTheme.textSecondary)
                            ),
                          ],
                        ),
                      ),
                      trailing: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: TaxiTheme.success,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          'ACTIVO',
                          style: TextStyle(
                            color: TaxiTheme.surfaceWhite,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.0,
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