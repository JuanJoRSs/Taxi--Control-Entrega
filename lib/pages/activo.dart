import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../theme/app_theme.dart'; //Se importa el Token Theme para poder reciclcar los calores predefinidos y ganar uniformidad

class Activo extends StatefulWidget {
  const Activo({super.key});

  @override
  State<Activo> createState() => _ActivoState();
}

class _ActivoState extends State<Activo> {

  final _supabase = Supabase.instance.client; // Conexión a la base de datos
  List<dynamic> _activos = []; // Lista para guardar los conductores en turno
  bool _cargando = true; // Control del círculo de carga

  @override
  void initState() {
    super.initState();
    _obtenerActivos(); // Ejectuamos la función para obtener los conductores activos al iniciar la pantalla
  }

  
  Future<void> _obtenerActivos() async { //Función asíncrona para obtener los conductores activos
    try {
      setState(() => _cargando = true);

      final data = await _supabase
          .from('fichajes')
          .select('*, conductores(nombre)')
          .isFilter('hora_salida', null);

      if (mounted) { //Mounted nos permite verififcar si el widget que estamos intentando actualizar sigue en el árbol de widgets
        setState(() {
          _activos = data; //Asignamos data a la variable de estado _activos para mostrarlo en el initState nada más se entre a la pantalla
          _cargando = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _cargando = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error de sincronización: $e'),
            backgroundColor: TaxiTheme.error,  //Si hay error se muestra mensaje con el color del Token Theme junto con lo que devuelve el error
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      //  Lee si es de día o de noche
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text(
          'Conductores Activos', //Título del AppBar
          style: TaxiTheme.tituloAppBar,
        ),
        centerTitle: true,
        backgroundColor: TaxiTheme.primaryDark, //Azul oscuro para el fondo del AppBar
        elevation: 0,
        iconTheme: const IconThemeData(color: TaxiTheme.surfaceWhite),
        actions: [
          IconButton(
            icon: const Icon(Icons.sync), //Icono para refrescar, intuitivo para el user
            onPressed: _obtenerActivos,
            tooltip: 'Refrescar', //Tooltip sirve para dar una especie de "hint" al usuario sobre que hace el botón
          ),
        ],
      ),
      body: _cargando
          ? const Center(
              child: CircularProgressIndicator(color: TaxiTheme.accentGold), //En caso de estar cargando decora así
            )
          : _activos.isEmpty 
          ? const Center(
              child: Text( //Si ya ha cargado y no hay nadie trabajando se muestra en gris el mensaje
                'No hay conductores operativos ahora mismo.', 
                style: TextStyle(color: TaxiTheme.textSecondary),
              ),
            )
          : RefreshIndicator(
              color: TaxiTheme.primaryDark,
              onRefresh: _obtenerActivos,
              child: ListView.builder(//ListView construye una lista de forma que solo renderiza lo que se ve, sin nada de fondo. Eficiente para que no tarde cargadno
                padding: const EdgeInsets.all(20),
                itemCount: _activos.length,
                itemBuilder: (context, index) {//Index para recorrer la lista de conductores activos (Sustituo de la iteración en Flutter)
                  final fichaje = _activos[index];
                  final nombre = fichaje['conductores']?['nombre'] ?? 'Sin Identificar';

                  String hora = fichaje['hora_entrada']?.toString().substring(11, 16) ?? '--:--'; //Declaracion de la variable que la hora de entrada

                  return Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    //  Reutilizamos tu sombra pero el color de fondo lo decide el tema
                    decoration: TaxiTheme.decoracionTarjeta.copyWith(
                      color: Theme.of(context).cardColor,
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(15),
                      leading: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: TaxiTheme.success.withOpacity(0.1), 
                          shape: BoxShape.circle
                        ),
                        child: const Icon(
                          Icons.directions_car_filled, // Icono de taxi para rellenar la tarjeta
                          color: TaxiTheme.success,
                        ),
                      ),
                      title: Text( //Titulo de la tarjeta, siendo este el propio nombre traido de Supabase
                        nombre.toUpperCase(), 
                        style: TextStyle(
                          fontWeight: FontWeight.w800, 
                          //  El nombre cambia de color según el fondo
                          color: Theme.of(context).textTheme.bodyLarge?.color,
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
                              'En servicio desde las $hora', //Para más información traemos la hora de entrada
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
                        child: const Text( //Detalle estetico para resaltar la tarjeta de activo
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