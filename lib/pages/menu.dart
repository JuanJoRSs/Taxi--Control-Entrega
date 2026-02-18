import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../theme/app_theme.dart'; // <--- IMPORTANTE: Asegúrate de que la ruta sea correcta

class MenuPrincipal extends StatefulWidget {
  const MenuPrincipal({super.key});

  @override
  State<MenuPrincipal> createState() => _MenuPrincipalState();
}

class _MenuPrincipalState extends State<MenuPrincipal> {
  final _supabase = Supabase.instance.client;
  bool _esAdmin = false;
  bool _cargando = true;

  @override
  void initState() {
    super.initState();
    _comprobarPermisos();
  }

  Future<void> _comprobarPermisos() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user != null) {
        final data = await _supabase
            .from('conductores')
            .select('es_admin')
            .eq('auth_id', user.id)
            .single();

        if (mounted) {
          setState(() {
            _esAdmin = data['es_admin'] ?? false;
            _cargando = false;
          });
        }
      }
    } catch (e) {
      if (mounted) setState(() => _cargando = false);
    }
  }

  void _navegarA(String ruta) {
    Navigator.pushNamed(context, ruta);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TaxiTheme.fondoApp,
      appBar: AppBar(
        backgroundColor: TaxiTheme.azulPrincipal,
        elevation: 0,
        title: const Text(
          'TAXI CONTROL',
          // TOKEN: Estilo de texto de la AppBar
          style: TaxiTheme.tituloAppBar,
        ),
        centerTitle: true,
        iconTheme: const IconThemeData(color: TaxiTheme.blancoPuro),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await _supabase.auth.signOut();
              if (mounted) Navigator.pushReplacementNamed(context, '/');
            },
          ),
        ],
      ),
      body: _cargando
          ? const Center(child: CircularProgressIndicator())
          : Center(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20.0,
                    vertical: 10,
                  ),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 400),
                    child: GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: 3,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: 1.1,
                      children: [
                        _botonMenu(
                          Icons.timer,
                          'Fichaje',
                          true,
                          TaxiTheme.azulPrincipal,
                          '/fichaje',
                        ),
                        _botonMenu(
                          Icons.business,
                          'Agencias',
                          true,
                          TaxiTheme.azulPrincipal,
                          '/agencias',
                        ),
                        _botonMenu(
                          Icons.visibility,
                          'Activos',
                          _esAdmin,
                          TaxiTheme.grisTextoSecundario,
                          '/activos',
                        ),
                        _botonMenu(
                          Icons.comment,
                          'Notas Coche',
                          true,
                          Colors.teal,
                          '/notas-vehiculo',
                        ),
                        _botonMenu(
                          Icons.euro,
                          'Liquidación',
                          true,
                          TaxiTheme.aviso,
                          '/liquidacion',
                        ),
                        _botonMenu(
                          Icons.groups,
                          'Plantilla',
                          _esAdmin,
                          TaxiTheme.aviso,
                          '/gestion-plantilla',
                        ),
                        _botonMenu(
                          Icons.history,
                          'Historial',
                          true,
                          TaxiTheme.grisTextoSecundario,
                          '/historial',
                        ),
                        _botonMenu(
                          Icons.picture_as_pdf,
                          'Export PDF',
                          _esAdmin,
                          TaxiTheme.grisTextoSecundario,
                          '/export',
                        ),
                        _botonMenu(
                          Icons.map,
                          'Estaciones de Servicio',
                          true,
                          TaxiTheme.exito,
                          '/mapa',
                        ),
                        _botonMenu(
                          Icons.warning_amber,
                          'Tráfico',
                          true,
                          TaxiTheme.alerta,
                          '/trafico',
                        ),
                        _botonMenu(
                          Icons.local_phone,
                          'Teléfonos',
                          true,
                          TaxiTheme.grisTextoSecundario,
                          '/telefonos',
                        ),
                        _botonMenu(
                          Icons.settings,
                          'Ajustes',
                          true,
                          Colors.grey,
                          '/ajustes',
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
    );
  }

  Widget _botonMenu(
    IconData icono,
    String texto,
    bool habilitado,
    Color color,
    String ruta,
  ) {
    return Opacity(
      opacity: habilitado ? 1.0 : 0.3,
      child: Container(
        // TOKEN: Decoración unificada (Card + Sombra + Border)
        decoration: TaxiTheme.decoracionTarjeta,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: habilitado ? () => _navegarA(ruta) : null,
            // TOKEN: Radio de borde
            borderRadius: BorderRadius.circular(TaxiTheme.radioTarjeta),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icono, size: 26, color: habilitado ? color : Colors.grey),
                const SizedBox(height: 5),
                Text(
                  texto,
                  textAlign: TextAlign.center,
                  // TOKEN: Estilo de texto del Grid
                  style: TaxiTheme.textoBotonGrid,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
