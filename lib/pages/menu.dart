//Imports
import 'package:flutter/material.dart'; //Botones, colores, iconos...
import 'package:supabase_flutter/supabase_flutter.dart'; //Conexión a base de datos.
import '../theme/app_theme.dart'; //Colores y estilos.

//Pantalla
//StatefulWidget significa que es una pantalla que puede cambiar de estado (mostrar un circulo de carga y luego mostrar los botones).
class MenuPrincipal extends StatefulWidget {
  const MenuPrincipal({super.key});

  @override
  State<MenuPrincipal> createState() => _MenuPrincipalState();
}

class _MenuPrincipalState extends State<MenuPrincipal> {
  //Variables
  //Conexión a Supabase
  final _supabase = Supabase.instance.client;
  
  //Guardaremos aqui si el usuario es administrador, por defecto no, por eso es false.
  bool _esAdmin = false;
  
  //Circulo de carga mientras le preguntamos a Supabase.
  bool _cargando = true;

  //Arranque
  //initState es lo primero que se ejecuta al abrir esta pantalla.
  @override
  void initState() {
    super.initState();
    //Nada más abrir la pantalla miramos que rol tiene el usuario.
    _comprobarPermisos();
  }

  //Permisos
  //Esta función va a Supabase a mirar quién ha iniciado sesión.
  Future<void> _comprobarPermisos() async {
    try {
      //Buscamos al usuario que acaba de poner su email y contraseña.
      final user = _supabase.auth.currentUser;
      
      if (user != null) {
        //Le decimos a Supabase que busque en la tabla si esta persona es admin.
        final data = await _supabase
            .from('conductores')
            .select('es_admin')
            .eq('auth_id', user.id)
            .single();

        //Si la pantalla sigue abierta (mounted), actualizamos los datos.
        if (mounted) {
          setState(() { //setState le dice a la pantalla que hay datos nuevos.
            _esAdmin = data['es_admin'] ?? false; //Guardamos si es admin o no.
            _cargando = false; //Quitamos el círculo de carga.
          });
        }
      }
    } catch (e) {
      //Si hay un error quitamos la carga para que no se quede bloqueado.
      if (mounted) setState(() => _cargando = false);
    }
  }

  //Navegacion
  //Una función para viajar a otras pantallas cuando se toca un botón.
  void _navegarA(String ruta) {
    Navigator.pushNamed(context, ruta);
  }

  //Dibujar
  //El método 'build' se encarga de dibujar todo lo que ves en el móvil.
  @override
  Widget build(BuildContext context) {
    //Scaffold es el esqueleto de la pantalla tiene barra superior, cuerpo, fondo.
    return Scaffold(
      //  FONDO PANTALLA DINÁMICO
      backgroundColor: Theme.of(context).scaffoldBackgroundColor, 
      
      //TopBar
      appBar: AppBar(
        backgroundColor: TaxiTheme.primaryDark,
        elevation: 0,
        title: const Text('PANEL DE CONTROL', style: TaxiTheme.tituloAppBar),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          //Botón de cerrar sesión en la esquina superior derecha.
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await _supabase.auth.signOut();
              if (!context.mounted) return; //Si el context ya no existe, cancela la acción
              Navigator.pushReplacementNamed(context, '/'); //Si existe, navega normal
            },
          ),
        ],
      ),

      //Cuerpo
      //Preguntamos si está cargando
      body: _cargando
          //Si es verdad mostramos el circulito dando vueltas.
          ? const Center(child: CircularProgressIndicator(color: TaxiTheme.accentGold))
          //Si es falso dibujamos la cuadrícula con los botones.
          : Center(
              child: SingleChildScrollView( //Permite hacer scroll si la pantalla es muy pequeña.
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 20),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 400),
                    child: Column(
                      children: [
                        Container(
                          height: 120, 
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 20,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: Image.asset('assets/images/logo.png'), //Logo
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'TAXI CONTROL',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 2,
                            //  TEXTO DINÁMICO: El logo cambia según el tema
                            color: Theme.of(context).textTheme.bodyLarge?.color,
                          ),
                        ),
                        const SizedBox(height: 35),

                        //GridView es el componente que crea la matriz de cuadritos.
                        GridView.count(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          crossAxisCount: 3, //Le decimos que queremos 3 columnas.
                          mainAxisSpacing: 12, //Espacio vertical entre botones.
                          crossAxisSpacing: 12, // Espacio horizontal entre botones.
                          childAspectRatio: 1.1, //Hace que los botones sean cuadrados.
                          
                          //Lista de botones
                          children: [
                            //Estos botones los ven todos los usuarios (Admin y Taxistas)
                            _botonMenu(Icons.timer, 'Fichaje', TaxiTheme.primaryDark, '/fichaje'),
                            _botonMenu(Icons.business, 'Agencias', TaxiTheme.primaryDark, '/agencias'),
                            
                            //El 'if' evalúa si eres admin. 
                            //Si no lo eres, este botón no se añade y el hueco se rellena automáticamente.
                            if (_esAdmin)
                              _botonMenu(Icons.visibility, 'Activos', TaxiTheme.primaryDark, '/activos'),
                            
                            _botonMenu(Icons.comment, 'Notas Coche', TaxiTheme.primaryDark, '/notas-coche'),
                            _botonMenu(Icons.euro, 'Liquidación', TaxiTheme.accentGold, '/facturacion'),
                            
                            //Solo Admin
                            if (_esAdmin)
                              _botonMenu(Icons.groups, 'Plantilla', TaxiTheme.primaryDark, '/gestion-plantilla'),
                            
                            _botonMenu(Icons.history, 'Historial', TaxiTheme.primaryDark, '/historial'),
                            
                            //Solo Admin
                            if (_esAdmin)
                              _botonMenu(Icons.picture_as_pdf, 'Export PDF', TaxiTheme.primaryDark, '/export'),
                            
                            //Cambiamos el icono al surtidor y la ruta a '/estaciones' para que conecte con main.dart
                            _botonMenu(Icons.local_gas_station, 'Estaciones', TaxiTheme.primaryDark, '/estaciones'),
                            _botonMenu(Icons.warning_amber, 'Tráfico', TaxiTheme.warning, '/trafico'),
                            // CORREGIDO: Cambiado de textSecondary a primaryDark
                            _botonMenu(Icons.local_phone, 'Teléfonos', TaxiTheme.primaryDark, '/agenda'),
                            // CORREGIDO: Cambiado de textSecondary a primaryDark
                            _botonMenu(Icons.settings, 'Ajustes', TaxiTheme.primaryDark, '/ajustes'),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
    );
  }

  //Fabricador de Botones individuales 
  //Recibe un icono, un texto, un color y una ruta, y fabrica el cuadrito con el boton.
  Widget _botonMenu(IconData icono, String texto, Color color, String ruta) {
    return Container(
      decoration: TaxiTheme.decoracionTarjeta.copyWith(
        //  FONDO TARJETA DINÁMICO
        color: Theme.of(context).cardColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05), 
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell( //InkWell crea el efecto de ondulación al tocar el botón.
          onTap: () => _navegarA(ruta), //Al tocar, viaja a la ruta que le pasamos.
          borderRadius: BorderRadius.circular(TaxiTheme.radioTarjeta),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center, //Centra el icono y el texto verticalmente.
            children: [
              Icon(icono, size: 26, color: color), //Dibuja el icono.
              const SizedBox(height: 5), //Espacio en blanco.
              Text(
                texto,
                textAlign: TextAlign.center,
                //  TEXTO DINÁMICO: Combina tu estilo base con el color dinámico
                style: TaxiTheme.textoBotonGrid.copyWith(
                  color: Theme.of(context).textTheme.bodyLarge?.color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}