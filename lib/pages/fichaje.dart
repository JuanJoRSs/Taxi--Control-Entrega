import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../theme/app_theme.dart'; // <--- Importamos los tokens premium

class Fichaje extends StatefulWidget {
  const Fichaje({super.key});

  @override
  State<Fichaje> createState() => _FichajeState();
}

class _FichajeState extends State<Fichaje> {
  final _supabase = Supabase.instance.client;

  int? _idConductor;
  int? _idFichajeActivo;
  String? _nombreConductor;
  bool _estaCargando = true;

  @override
  void initState() {
    super.initState();
    _checkEstado();
  }

  // Comprobar si el conductor tiene una sesión abierta en la base de datos
  Future<void> _checkEstado() async {
    final user = _supabase.auth.currentUser;
    if (user == null) {
      if (mounted) Navigator.of(context).pushReplacementNamed('/');
      return;
    }

    try {
      final conductor = await _supabase
          .from('conductores')
          .select('id_conductor, nombre')
          .eq('auth_id', user.id)
          .maybeSingle();

      if (conductor == null) throw 'Perfil no encontrado';

      _idConductor = conductor['id_conductor'];
      _nombreConductor = conductor['nombre'];

      final fichaje = await _supabase
          .from('fichajes')
          .select('id')
          .eq('id_conductor', _idConductor!)
          .isFilter('hora_salida', null)
          .maybeSingle();

      if (mounted) {
        setState(() {
          _idFichajeActivo = fichaje?['id'];
          _estaCargando = false;
        });
      }
    } catch (e) {
      _manejarError('Error al sincronizar: $e');
    }
  }

  // Registrar entrada o salida
  Future<void> _gestionarFichaje() async {
    if (_idConductor == null) return;

    setState(() => _estaCargando = true);
    final esEntrada = _idFichajeActivo == null;

    try {
      if (esEntrada) {
        final response = await _supabase
            .from('fichajes')
            .insert({'id_conductor': _idConductor})
            .select('id')
            .single();

        setState(() => _idFichajeActivo = response['id']);
      } else {
        await _supabase
            .from('fichajes')
            .update({'hora_salida': DateTime.now().toUtc().toIso8601String()})
            .eq('id', _idFichajeActivo!);

        setState(() => _idFichajeActivo = null);
      }
    } catch (e) {
      _manejarError('No se pudo registrar: $e');
    } finally {
      if (mounted) setState(() => _estaCargando = false);
    }
  }

  void _manejarError(String mensaje) {
    if (!mounted) return;
    setState(() => _estaCargando = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(mensaje), backgroundColor: TaxiTheme.error),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool estaEnTurno = _idFichajeActivo != null;

    return Scaffold(
      backgroundColor: TaxiTheme.backgroundLight, // TOKEN: Gris perla suave
      appBar: AppBar(
        title: const Text('REGISTRO DE JORNADA', style: TaxiTheme.tituloAppBar),
        centerTitle: true,
        backgroundColor: TaxiTheme.primaryDark, // TOKEN: Azul Noche
        elevation: 0,
        iconTheme: const IconThemeData(color: TaxiTheme.surfaceWhite),
      ),
      body: Center(
        child: _estaCargando
            ? const CircularProgressIndicator(color: TaxiTheme.accentGold) // Carga en Dorado
            : _ContenidoFichaje(
                nombre: _nombreConductor ?? 'Conductor',
                estaEnTurno: estaEnTurno,
                onTap: _gestionarFichaje,
              ),
      ),
    );
  }
}

class _ContenidoFichaje extends StatelessWidget {
  final String nombre;
  final bool estaEnTurno;
  final VoidCallback onTap;

  const _ContenidoFichaje({
    required this.nombre,
    required this.estaEnTurno,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
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
        const Text(
          'El registro quedará guardado con su ubicación actual',
          style: TextStyle(color: TaxiTheme.textSecondary, fontSize: 11),
        )
      ],
    );
  }
}