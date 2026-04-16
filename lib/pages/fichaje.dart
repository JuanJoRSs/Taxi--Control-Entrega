import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../theme/app_theme.dart'; 

class Fichaje extends StatefulWidget {
  const Fichaje({super.key});

  @override
  State<Fichaje> createState() => _FichajeState();
}

class _FichajeState extends State<Fichaje> {
  final _supabase = Supabase.instance.client;

//Declaramos las varibles para almacenar id, nombre y estado del conductor
  int? _idConductor; 
  int? _idFichajeActivo;
  String? _nombreConductor;
  bool _estaCargando = true;

  @override
  void initState() { //Iniciamos el estado invocando la función para saber si pintamos el botón de entrada o salida
    super.initState();
    _checkEstado();
  }

  Future<void> _checkEstado() async { //Método para verificar el estado del conductor y su fichaje activo
    final user = _supabase.auth.currentUser; //Comprobamos si el usuario está autenticado, si no lo redirigimos al login
    if (user == null) {
      if (mounted) Navigator.of(context).pushReplacementNamed('/');
      return;
    }

    try {
      final conductor = await _supabase //Query para obtener el id y nombre del conductor a partir del auth_id del usuario autenticado
          .from('conductores')
          .select('id_conductor, nombre')
          .eq('auth_id', user.id)
          .maybeSingle();

      if (conductor == null) throw 'Perfil no encontrado';

      _idConductor = conductor['id_conductor']; //Si pasa el check, almacenamos el id y nombre del conductor en las variables de estado
      _nombreConductor = conductor['nombre'];

      final fichaje = await _supabase //Query en busca para un fichaje con hora de entrada pero sin salida, dando la lógica de que hay que pintar el botón de salida si se encuentra uno, o el de entrada si no se encuentra ninguno
          .from('fichajes')
          .select('id')
          .eq('id_conductor', _idConductor!)
          .isFilter('hora_salida', null)
          .maybeSingle();

      if (mounted) { //Si el widget sigue montado, actualizamos el estado con el id del fichaje activo y desactivamos la carga
        setState(() {
          _idFichajeActivo = fichaje?['id'];
          _estaCargando = false;
        });
      }
    } catch (e) {
      _manejarError('Error al sincronizar: $e');
    }
  }

  Future<void> _gestionarFichaje() async { //Método para entrar/salir dependiendo del estado que se encuentre antes de pulsar
    if (_idConductor == null) return;

    setState(() => _estaCargando = true);
    final esEntrada = _idFichajeActivo == null;

    try { 
      if (esEntrada) { //Si es una entrada, insertamos un registro con la hora de entrada, uniendolo con el id y dejando en null la hora de salida
        final response = await _supabase
            .from('fichajes')
            .insert({'id_conductor': _idConductor})
            .select('id')
            .single();

        setState(() => _idFichajeActivo = response['id']);
      } else {
        await _supabase //Si es una salida updateamos la tabla modificando el registro con la hora de salida actual
            .from('fichajes')
            .update({'hora_salida': DateTime.now().toUtc().toIso8601String()})
            .eq('id', _idFichajeActivo!);

        setState(() => _idFichajeActivo = null); //Y limpiamos el id del fichaje activo para volver a pintar el botón de entrada
      }
    } catch (e) {
      _manejarError('No se pudo registrar: $e');
    } finally {
      if (mounted) setState(() => _estaCargando = false);
    }
  }

  void _manejarError(String mensaje) { //Método auxiliar para los errores
    if (!mounted) return;
    setState(() => _estaCargando = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(mensaje), backgroundColor: TaxiTheme.error),
    );
  }

  @override
  Widget build(BuildContext context) { //Widget que pinta la interfaz según el estado que reciba de la función _checkEstado
    final bool estaEnTurno = _idFichajeActivo != null; //Variable estaEnTurno para no manejar la lógica de si es entrada o salida en el widget, sino solo pintar según el estado que reciba

    return Scaffold(
      backgroundColor: TaxiTheme.backgroundLight,
      appBar: AppBar(
        title: const Text('REGISTRO DE JORNADA', style: TaxiTheme.tituloAppBar),
        centerTitle: true,
        backgroundColor: TaxiTheme.primaryDark, 
        elevation: 0,
        iconTheme: const IconThemeData(color: TaxiTheme.surfaceWhite),
      ),
      body: Center(
        child: _estaCargando
            ? const CircularProgressIndicator(color: TaxiTheme.accentGold)
            : _ContenidoFichaje(
                nombre: _nombreConductor ?? 'Conductor',
                estaEnTurno: estaEnTurno,
                onTap: _gestionarFichaje,
              ),
      ),
    );
  }
}

class _ContenidoFichaje extends StatelessWidget { //
  final String nombre;
  final bool estaEnTurno;
  final VoidCallback onTap;

  const _ContenidoFichaje({
    required this.nombre,
    required this.estaEnTurno,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) { //Widget que pinta el contenido del fichaje, con un indicador visual del estado, el nombre del conductor, una etiqueta de estado y un botón de acción principal que cambia según el estado
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Indicador visual de estado Premium
        Container(
          padding: const EdgeInsets.all(30),
          decoration: BoxDecoration(
            color: estaEnTurno
                ? TaxiTheme.success.withOpacity(0.1)
                : TaxiTheme.primaryDark.withOpacity(0.05),
            shape: BoxShape.circle,
            boxShadow: [
              if (estaEnTurno)
                BoxShadow(
                  color: TaxiTheme.success.withOpacity(0.2),
                  blurRadius: 20,
                  spreadRadius: 5,
                )
            ],
          ),
          child: Icon(
            estaEnTurno ? Icons.check_circle : Icons.radio_button_off,
            size: 100,
            color: estaEnTurno ? TaxiTheme.success : TaxiTheme.textSecondary,
          ),
        ),
        const SizedBox(height: 40),
        Text(
          'Hola, $nombre',
          style: const TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w800,
            color: TaxiTheme.primaryDark,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 10),
        // Etiqueta de estado profesional
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          decoration: BoxDecoration(
            color: estaEnTurno ? TaxiTheme.success : TaxiTheme.textSecondary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            estaEnTurno ? 'SESIÓN ACTIVA' : 'FUERA DE SERVICIO',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
              color: estaEnTurno ? TaxiTheme.surfaceWhite : TaxiTheme.textSecondary,
            ),
          ),
        ),
        const SizedBox(height: 80),
        // Botón de Acción Principal
        SizedBox(
          width: 300,
          height: 65,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              // Si está en turno, el botón es el rojo de error. Si no, el azul principal.
              backgroundColor: estaEnTurno ? TaxiTheme.error : TaxiTheme.primaryDark,
              foregroundColor: TaxiTheme.surfaceWhite,
              elevation: 4,
              shadowColor: (estaEnTurno ? TaxiTheme.error : TaxiTheme.primaryDark).withOpacity(0.4),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(TaxiTheme.radioTarjeta),
              ),
            ),
            onPressed: onTap,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(estaEnTurno ? Icons.stop_rounded : Icons.play_arrow_rounded, size: 28),
                const SizedBox(width: 12),
                Text(
                  estaEnTurno ? 'FINALIZAR JORNADA' : 'INICIAR JORNADA',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.1,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }
}