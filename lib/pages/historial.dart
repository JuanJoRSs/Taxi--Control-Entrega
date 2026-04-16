//Imports
import 'package:flutter/material.dart'; //Botones, colores, iconos...
import 'package:supabase_flutter/supabase_flutter.dart'; //Conexión a base de datos.
import 'package:intl/intl.dart'; //Para dar un formato bonito a las fechas y horas.
import '../theme/app_theme.dart'; //Colores y estilos corporativos.

//Pantalla
//Usamos StatefulWidget porque la pantalla cambiará primero muestra carga, luego la lista de datos.
class HistorialPage extends StatefulWidget {
  const HistorialPage({super.key});

  @override
  State<HistorialPage> createState() => _HistorialPageState();
}

class _HistorialPageState extends State<HistorialPage> {
  //Variables
  //Instanciamos el cliente de Supabase para las peticiones al servidor.
  final _supabase = Supabase.instance.client;
  
  //Lista donde guardaremos el historial de fichajes que nos devuelva la base de datos.
  List<dynamic> _historial = [];
  
  //Círculo de carga mientras le preguntamos a Supabase.
  bool _cargando = true;

  //Variable para guardar la opción seleccionada en el desplegable. Por defecto "Este Mes".
  String _filtroFrecuencia = 'Este Mes';

  //Variables admin
  bool _esAdmin = false; //Saber si el usuario es administrador.
  List<dynamic> _listaConductores = []; //Lista para el desplegable de admin.
  String? _conductorSeleccionado; //El ID del conductor que el admin quiere ver.

  //Arranque
  //initState es lo primero que se ejecuta al abrir esta pantalla.
  @override
  void initState() {
    super.initState();
    //Nada más abrir la pantalla buscamos el historial del conductor.
    _inicializarPantalla();
  }

  //Logica
  //Función para saber si es admin, cargar lista y luego historial).
  Future<void> _inicializarPantalla() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return;

      //Buscamos si es admin y su ID.
      final datosConductor = await _supabase
          .from('conductores')
          .select('id_conductor, es_admin')
          .eq('auth_id', user.id)
          .single();

      _esAdmin = datosConductor['es_admin'] ?? false;

      //Si es admin, descargamos la lista de todos los conductores para el filtro.
      if (_esAdmin) {
        final dataConductores = await _supabase
            .from('conductores')
            .select('id_conductor, nombre, apellido')
            .eq('es_admin', false) //Solo traemos a los que no son admin
            .order('nombre');
        _listaConductores = dataConductores;
      }

      //Una vez sabemos quién es, bajamos el historial.
      await _obtenerHistorial(idConductorActual: datosConductor['id_conductor']);

    } catch (e) {
      debugPrint('Error inicializando: $e');
      if (mounted) setState(() => _cargando = false);
    }
  }

  //Función para descargar los registros según el filtro.
  Future<void> _obtenerHistorial({int? idConductorActual}) async {
    try {
      //Activamos el estado de carga por si estamos refrescando la pantalla.
      setState(() => _cargando = true);

      final user = _supabase.auth.currentUser;
      if (user == null) return;

      //Si no nos pasaron el ID (ej: al usar el botón de refrescar), lo buscamos rápido.
      int idBuscado = idConductorActual ?? 0;
      if (idConductorActual == null && !_esAdmin) {
         final d = await _supabase.from('conductores').select('id_conductor').eq('auth_id', user.id).single();
         idBuscado = d['id_conductor'];
      }

      //2. Calculamos las fechas según lo que el usuario haya elegido en el desplegable.
      DateTime ahora = DateTime.now();
      String? fechaInicioStr;
      String? fechaFinStr;

      if (_filtroFrecuencia == 'Hoy') {
        fechaInicioStr = DateFormat('yyyy-MM-dd').format(ahora);
      } else if (_filtroFrecuencia == 'Esta Semana') {
        fechaInicioStr = DateFormat('yyyy-MM-dd').format(ahora.subtract(const Duration(days: 7))); //Últimos 7 días
      } else if (_filtroFrecuencia == 'Este Mes') {
        fechaInicioStr = DateFormat('yyyy-MM-dd').format(DateTime(ahora.year, ahora.month, 1)); //Desde el día 1 de este mes
      } else if (_filtroFrecuencia == 'Mes Anterior') {
        fechaInicioStr = DateFormat('yyyy-MM-dd').format(DateTime(ahora.year, ahora.month - 1, 1)); //Día 1 del mes pasado
        fechaFinStr = DateFormat('yyyy-MM-dd').format(DateTime(ahora.year, ahora.month, 0)); //Último día del mes pasado
      } else if (_filtroFrecuencia == 'Este Año') {
        fechaInicioStr = DateFormat('yyyy-MM-dd').format(DateTime(ahora.year, 1, 1)); //Desde el 1 de Enero
      }
      //Si es 'Todos', las fechas se quedan en null para que traiga todo el historial.

      //3. Preparamos la consulta a la tabla 'fichajes'.
      var consulta = _supabase.from('fichajes').select('*, conductores(nombre, apellido)');

      //Si NO es admin, le ponemos un filtro para que solo vea SUS propios fichajes.
      if (!_esAdmin) {
        consulta = consulta.eq('id_conductor', idBuscado);
      } else {
        //Si ES admin y seleccionó un conductor en el filtro, buscamos solo ese.
        if (_conductorSeleccionado != null) {
          consulta = consulta.eq('id_conductor', int.parse(_conductorSeleccionado!));
        }
      }

      //Aplicamos los filtros de fecha si existen.
      if (fechaInicioStr != null) {
        consulta = consulta.gte('fecha_fichaje', fechaInicioStr);
      }
      if (fechaFinStr != null) {
        consulta = consulta.lte('fecha_fichaje', fechaFinStr);
      }

      //Ejecutamos la consulta ordenando los más recientes primero.
      final datosHistorial = await consulta
          .order('fecha_fichaje', ascending: false)
          .limit(100); //Ampliamos el límite para cuando seleccionen "Todos" o "Este Año".

      //Si la pantalla sigue abierta, actualizamos la lista con los datos descargados.
      if (mounted) {
        setState(() {
          _historial = datosHistorial;
          _cargando = false; //Quitamos el círculo de carga.
        });
      }
    } catch (e) {
      //Si hay un error de conexión, lo capturamos y quitamos la carga.
      debugPrint('Error cargando historial: $e');
      if (mounted) {
        setState(() => _cargando = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error al cargar el historial'),
            backgroundColor: TaxiTheme.error,
          ),
        );
      }
    }
  }

  //Dibujar
  //El método build dibuja lo que ve el usuario en la pantalla.
  @override
  Widget build(BuildContext context) {
    //Scaffold es el esqueleto de la pantalla.
    return Scaffold(
      // ✅ 1. FONDO PANTALLA DINÁMICO
      backgroundColor: Theme.of(context).scaffoldBackgroundColor, 
      
      //TopBar
      appBar: AppBar(
        backgroundColor: TaxiTheme.primaryDark,
        elevation: 0,
        title: const Text('HISTORIAL DE ACTIVIDAD', style: TaxiTheme.tituloAppBar),
        centerTitle: true, //Centramos el título.
        iconTheme: const IconThemeData(color: Colors.white), //Aseguramos que la flecha de volver sea blanca.
        actions: [
          //Botón de refrescar en la esquina superior derecha.
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _obtenerHistorial(), //Al pulsar, vuelve a descargar los datos.
          ),
        ],
      ),

      //Cuerpo organizado en una columna para poner el filtro arriba y la lista abajo.
      body: Column(
        children: [
          //Caja superior con los selectores.
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
            child: Column(
              children: [
                //--- NUEVO: FILTRO DE CONDUCTOR SOLO PARA ADMIN ---
                if (_esAdmin) ...[
                  Container(
                    // ✅ 2. FONDO TARJETA DINÁMICO
                    decoration: TaxiTheme.decoracionTarjeta.copyWith(
                      color: Theme.of(context).cardColor,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05), //Sombra suave y profesional.
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 15),
                    margin: const EdgeInsets.only(bottom: 12),                    
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        isExpanded: true,
                        hint: const Text('Todos los conductores', style: TextStyle(color: TaxiTheme.textSecondary)),
                        value: _conductorSeleccionado,
                        icon: Icon(Icons.person_search, color: Theme.of(context).colorScheme.secondary),
                        items: [
                          //Añadimos la opción "Todos" al principio
                          DropdownMenuItem<String>(
                            value: null,
                            // ✅ 3. COLOR DE TEXTO DINÁMICO
                            child: Text('Todos los conductores', style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).textTheme.bodyLarge?.color)),
                          ),
                          ..._listaConductores.map((c) {
                            return DropdownMenuItem<String>(
                              value: c['id_conductor'].toString(),
                              // ✅ 3. COLOR DE TEXTO DINÁMICO
                              child: Text("${c['nombre']} ${c['apellido'] ?? ''}", style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).textTheme.bodyLarge?.color)),
                            );
                          })
                        ],
                        onChanged: (String? nuevoValor) {
                          setState(() {
                            _conductorSeleccionado = nuevoValor;
                          });
                          _obtenerHistorial();
                        },
                      ),
                    ),
                  ),
                ],

                //Caja con el selector de tiempo ampliado.
                Container(
                  // ✅ 2. FONDO TARJETA DINÁMICO
                  decoration: TaxiTheme.decoracionTarjeta.copyWith(
                    color: Theme.of(context).cardColor,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05), //Sombra suave y profesional.
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 15),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      isExpanded: true, //Ocupa todo el ancho disponible.
                      value: _filtroFrecuencia, //El valor actual seleccionado.
                      icon: Icon(Icons.calendar_today, color: Theme.of(context).colorScheme.secondary, size: 20),
                      //Lista ampliada de opciones
                      items: ['Hoy', 'Esta Semana', 'Este Mes', 'Mes Anterior', 'Este Año', 'Todos'].map((String valor) {
                        return DropdownMenuItem<String>(
                          value: valor,
                          // ✅ 3. COLOR DE TEXTO DINÁMICO
                          child: Text(
                            valor, 
                            style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).textTheme.bodyLarge?.color)
                          ),
                        );
                      }).toList(),
                      onChanged: (String? nuevoValor) {
                        if (nuevoValor != null) {
                          //Si el usuario cambia la opción, guardamos el cambio y volvemos a descargar la base de datos.
                          setState(() {
                            _filtroFrecuencia = nuevoValor;
                          });
                          _obtenerHistorial();
                        }
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),

          //La lista de resultados envuelta en Expanded para que ocupe el resto de la pantalla.
          Expanded(
            //Preguntamos si está cargando.
            child: _cargando
                //Si es verdad, mostramos el circulito dorado dando vueltas.
                ? const Center(child: CircularProgressIndicator(color: TaxiTheme.accentGold))
                //Si es falso, comprobamos si la lista está vacía.
                : _historial.isEmpty
                    //Si está vacía, mostramos un mensaje amigable.
                    ? const Center(
                        child: Text(
                          'No hay registros para esta búsqueda.',
                          style: TextStyle(color: TaxiTheme.textSecondary, fontSize: 16),
                        ),
                      )
                    //Si hay datos, dibujamos la lista (ListView) con los registros.
                    : ListView.separated(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                        itemCount: _historial.length, //Cuántos elementos hay en total.
                        separatorBuilder: (context, index) => const SizedBox(height: 12), //Espacio entre tarjetas.
                        itemBuilder: (context, index) {
                          final registro = _historial[index];
                          
                          //Formateamos la fecha para que se lea como "Día/Mes/Año".
                          final fechaParsed = DateTime.parse(registro['fecha_fichaje'].toString());
                          final fechaEspanola = DateFormat('dd/MM/yyyy').format(fechaParsed);
                          
                          //NUEVO: LÓGICA PARA JORNADAS QUE CRUZAN DE DÍA (EJ: Entra a las 14:00 y sale a las 17:00 del día siguiente)
                          String horaEntrada = '--:--';
                          String horaSalida = '--:--';
                          
                          if (registro['hora_entrada'] != null) {
                             final dateTimeEntrada = DateTime.parse(registro['hora_entrada']).toLocal();
                             horaEntrada = DateFormat('HH:mm').format(dateTimeEntrada);
                          }
                          
                          if (registro['hora_salida'] != null) {
                             final dateTimeSalida = DateTime.parse(registro['hora_salida']).toLocal();
                             final dateTimeEntrada = registro['hora_entrada'] != null ? DateTime.parse(registro['hora_entrada']).toLocal() : dateTimeSalida;
                             
                             //Si el día de salida es mayor al día de entrada, añadimos el texto "(Día sig.)" para que quede claro visualmente.
                             if (dateTimeSalida.day != dateTimeEntrada.day || dateTimeSalida.month != dateTimeEntrada.month) {
                                horaSalida = '${DateFormat('HH:mm').format(dateTimeSalida)} (Día sig.)';
                             } else {
                                horaSalida = DateFormat('HH:mm').format(dateTimeSalida);
                             }
                          }

                          //Si somos admin, mostramos el nombre del conductor.
                          final nombreConductor = registro['conductores'] != null ? '${registro['conductores']['nombre']} ${registro['conductores']['apellido'] ?? ''}' : 'Desconocido';

                          //Dibujamos la tarjeta individual para cada registro.
                          return Container(
                            // ✅ 2. FONDO TARJETA DINÁMICO
                            decoration: TaxiTheme.decoracionTarjeta.copyWith(
                              color: Theme.of(context).cardColor,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05), //Sombra suave y profesional.
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Row(
                                children: [
                                  //Icono decorativo a la izquierda.
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: TaxiTheme.primaryDark.withOpacity(0.1),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(Icons.access_time_filled, color: Theme.of(context).colorScheme.secondary),
                                  ),
                                  const SizedBox(width: 16),
                                  
                                  //Información central (Fecha y Nombre si es admin).
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Jornada del $fechaEspanola',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 15,
                                            // ✅ 3. COLOR DE TEXTO DINÁMICO
                                            color: Theme.of(context).textTheme.bodyLarge?.color,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        if (_esAdmin)
                                          Text(
                                            nombreConductor,
                                            style: const TextStyle(color: TaxiTheme.accentGold, fontWeight: FontWeight.bold, fontSize: 13),
                                          )
                                        else
                                          const Text(
                                            'Registro completado',
                                            style: TextStyle(color: TaxiTheme.textSecondary, fontSize: 12),
                                          ),
                                      ],
                                    ),
                                  ),
                                  
                                  //Horas a la derecha con los textos actualizados.
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        'Entrada: $horaEntrada',
                                        style: const TextStyle(fontWeight: FontWeight.w600, color: TaxiTheme.success),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Salida: $horaSalida',
                                        style: const TextStyle(fontWeight: FontWeight.w600, color: TaxiTheme.error),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}