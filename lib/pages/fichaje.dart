import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../theme/app_theme.dart'; // <--- Importamos los tokens

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
      SnackBar(content: Text(mensaje), backgroundColor: TaxiTheme.alerta),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool estaEnTurno = _idFichajeActivo != null;

    return Scaffold(
      backgroundColor: TaxiTheme.fondoApp, // TOKEN: Fondo suave
      appBar: AppBar(
        title: const Text('REGISTRO DE JORNADA', style: TaxiTheme.tituloAppBar),
        centerTitle: true,
        backgroundColor: TaxiTheme.azulPrincipal, // TOKEN: Azul unificado
        elevation: 0,
        iconTheme: const IconThemeData(color: TaxiTheme.blancoPuro),
      ),
      body: Center(
        child: _estaCargando
            ? const CircularProgressIndicator(color: TaxiTheme.azulPrincipal)
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
        // Indicador visual de estado
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: estaEnTurno
                ? TaxiTheme.exito.withOpacity(0.1)
                : TaxiTheme.grisBordes.withOpacity(0.2),
            shape: BoxShape.circle,
          ),
          child: Icon(
            estaEnTurno ? Icons.play_circle_filled : Icons.pause_circle_filled,
            size: 100,
            color: estaEnTurno
                ? TaxiTheme.exito
                : TaxiTheme.grisTextoSecundario,
          ),
        ),
        const SizedBox(height: 30),
        Text(
          'Hola, $nombre',
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: TaxiTheme.grisTextoPrincipal,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          estaEnTurno ? 'ESTÁS EN TURNO' : 'TURNO FINALIZADO',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.2,
            color: estaEnTurno ? TaxiTheme.exito : TaxiTheme.alerta,
          ),
        ),
        const SizedBox(height: 60),
        SizedBox(
          width: 280,
          height: 65,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              // Si está en turno, el botón es rojo (para salir). Si no, verde (para entrar).
              backgroundColor: estaEnTurno ? TaxiTheme.alerta : TaxiTheme.exito,
              foregroundColor: TaxiTheme.blancoPuro,
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(TaxiTheme.radioBoton),
              ),
            ),
            onPressed: onTap,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(estaEnTurno ? Icons.exit_to_app : Icons.login),
                const SizedBox(width: 10),
                Text(
                  estaEnTurno ? 'TERMINAR JORNADA' : 'INICIAR JORNADA',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
