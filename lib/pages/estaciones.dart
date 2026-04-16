//Imports
import 'dart:convert'; //Para descifrar los datos que nos envía Google (JSON).
import 'dart:ui' as ui; //Para dibujar el icono de Material en un lienzo digital.
import 'dart:typed_data'; //Para transformar el dibujo en datos legibles por el mapa.
import 'package:flutter/material.dart'; //Botones, colores, iconos...
import 'package:google_maps_flutter/google_maps_flutter.dart'; //Para dibujar el mapa de Google.
import 'package:geolocator/geolocator.dart'; //Para saber dónde está el taxista.
import 'package:http/http.dart' as http; //Para hacer peticiones a Internet (a la API de Google).
import '../theme/app_theme.dart'; //Colores y estilos corporativos.

//Pantalla
//StatefulWidget porque la pantalla cambiará: primero carga la ubicación y luego muestra el mapa con los marcadores.
class EstacionesPage extends StatefulWidget {
  const EstacionesPage({super.key});

  @override
  State<EstacionesPage> createState() => _EstacionesPageState();
}

class _EstacionesPageState extends State<EstacionesPage> {
  //Variables
  //Controlador del mapa para poder mover la cámara.
  GoogleMapController? _mapController;
  
  //Lista de chinchetas (marcadores) que pondremos en el mapa.
  final Set<Marker> _marcadores = {};
  
  //Para guardar la posición exacta del taxista.
  Position? _posicionActual;
  
  //Círculo de carga mientras buscamos el GPS y descargamos los datos.
  bool _cargando = true;

  //NUEVA VARIABLE: Para guardar nuestro icono personalizado.
  BitmapDescriptor? _iconoGasolinera;

  //Tu clave de API de Google (Reemplaza con tu clave real si es diferente).
  final String _apiKey = 'AIzaSyBCrZCJ6vqIt_9A01MsPShOeC0OXVHC8C0';

  //Arranque
  //initState es lo PRIMERO que se ejecuta al abrir esta pantalla.
  @override
  void initState() {
    super.initState();
    //Nada más abrir la pantalla, cargamos el icono, buscamos dónde estamos y luego las gasolineras.
    _cargarIcono().then((_) => _iniciarMapa());
  }

  //NUEVA FUNCIÓN: Dibuja el icono de Material (local_gas_station) y lo convierte en un marcador de mapa.
  Future<void> _cargarIcono() async {
    final ui.PictureRecorder pictureRecorder = ui.PictureRecorder();
    final Canvas canvas = Canvas(pictureRecorder);
    const double size = 40.0; // Tamaño del icono en el mapa

    // Dibujamos el icono de Material
    final TextPainter textPainter = TextPainter(
      textDirection: TextDirection.ltr,
    );
    textPainter.text = TextSpan(
      text: String.fromCharCode(Icons.local_gas_station.codePoint),
      style: TextStyle(
        fontSize: size,
        fontFamily: Icons.local_gas_station.fontFamily,
        color: TaxiTheme.accentGold, // Usamos tu color dorado para que resalte
      ),
    );
    textPainter.layout();
    textPainter.paint(canvas, const Offset(0.0, 0.0));

    // Convertimos el dibujo a una imagen que Google Maps entienda
    final ui.Image image = await pictureRecorder.endRecording().toImage(size.toInt(), size.toInt());
    final ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    final Uint8List uint8List = byteData!.buffer.asUint8List();

    _iconoGasolinera = BitmapDescriptor.fromBytes(uint8List);
  }

  //Logica
  //Función principal que agrupa pedir permisos, buscar ubicación y buscar estaciones.
  Future<void> _iniciarMapa() async {
    try {
      await _obtenerUbicacion();
      if (_posicionActual != null) {
        await _buscarGasolineras();
      }
    } catch (e) {
      debugPrint("Error al iniciar el mapa: $e");
    } finally {
      //Pase lo que pase, quitamos el círculo de carga para no bloquear la pantalla.
      if (mounted) {
        setState(() => _cargando = false);
      }
    }
  }

  //Función asíncrona para pedir permiso de GPS y obtener las coordenadas.
  Future<void> _obtenerUbicacion() async {
    bool servicioHabilitado = await Geolocator.isLocationServiceEnabled();
    if (!servicioHabilitado) return;

    LocationPermission permiso = await Geolocator.checkPermission();
    if (permiso == LocationPermission.denied) {
      permiso = await Geolocator.requestPermission();
      if (permiso == LocationPermission.denied) return;
    }
    
    if (permiso == LocationPermission.deniedForever) return;

    //Si nos dan permiso, guardamos la latitud y longitud.
    _posicionActual = await Geolocator.getCurrentPosition();
  }

  //Función asíncrona para buscar gasolineras usando la API de Google Places.
  Future<void> _buscarGasolineras() async {
    if (_posicionActual == null) return;

    final lat = _posicionActual!.latitude;
    final lng = _posicionActual!.longitude;
    final radioBuscado = 50000; // Buscamos en un radio de 50 km (máximo de Google) para abarcar toda la isla.

    //1. Construimos la URL original de Google.
    final String urlGoogle = 
        'https://maps.googleapis.com/maps/api/place/nearbysearch/json'
        '?location=$lat,$lng'
        '&radius=$radioBuscado'
        '&type=gas_station'
        '&key=$_apiKey';

    //2. Codificamos la URL (Uri.encodeComponent) para que el proxy la envíe intacta sin perder la clave.
    final String url = 'https://corsproxy.io/?${Uri.encodeComponent(urlGoogle)}';

    try {
      //Hacemos la llamada a Internet.
      final respuesta = await http.get(Uri.parse(url));

      if (respuesta.statusCode == 200) {
        final datos = json.decode(respuesta.body);
        final resultados = datos['results'] as List;

        //Limpiamos los marcadores viejos.
        _marcadores.clear();

        //Añadimos un marcador especial para nuestra ubicación actual.
        _marcadores.add(
          Marker(
            markerId: const MarkerId('mi_ubicacion'),
            position: LatLng(lat, lng),
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue), //Color azul para nosotros
            infoWindow: const InfoWindow(title: 'Mi Ubicación Actual'),
          ),
        );

        //Recorremos la lista de gasolineras que nos devolvió Google y creamos una chincheta para cada una.
        for (var lugar in resultados) {
          final ubicacionLugar = lugar['geometry']['location'];
          final latitudLugar = ubicacionLugar['lat'];
          final longitudLugar = ubicacionLugar['lng'];
          final nombreLugar = lugar['name'];

          _marcadores.add(
            Marker(
              markerId: MarkerId(lugar['place_id']),
              position: LatLng(latitudLugar, longitudLugar),
              //Usamos nuestro icono personalizado. Si por algún motivo falló al cargar, usamos el naranja por defecto.
              icon: _iconoGasolinera ?? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange), 
              infoWindow: InfoWindow(title: nombreLugar),
            ),
          );
        }
      } else {
        debugPrint('Error del servidor: Código ${respuesta.statusCode}');
      }
    } catch (e) {
      debugPrint('Error de conexión a la API: $e');
    }
  }

  //Dibujar
  //El método build dibuja lo que ve el usuario en la pantalla.
  @override
  Widget build(BuildContext context) {
    //Scaffold es el esqueleto de la pantalla.
    return Scaffold(
      // ✅ 1. FONDO DINÁMICO
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      
      //TopBar
      appBar: AppBar(
        title: const Text('ESTACIONES DE SERVICIO', style: TaxiTheme.tituloAppBar),
        centerTitle: true, //Centramos el título.
        backgroundColor: TaxiTheme.primaryDark,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white), //Aseguramos que la flecha de volver sea blanca.
        actions: [
          //Botón de refrescar clásico en la barra superior.
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() => _cargando = true);
              _iniciarMapa();
            },
          ),
        ],
      ),

      //Cuerpo
      //Preguntamos si está cargando.
      body: _cargando
          //Si es verdad, mostramos el circulito dorado dando vueltas.
          ? const Center(child: CircularProgressIndicator(color: TaxiTheme.accentGold))
          //Si es falso y no tenemos posición, mostramos un error.
          : _posicionActual == null
              // ✅ 2. TEXTO DINÁMICO (Por si no hay ubicación, que el error se lea bien en modo oscuro)
              ? Center(child: Text("No se pudo obtener la ubicación", style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color)))
              //Si es falso y TENEMOS posición, usamos Stack para dibujar el mapa y poner botones encima.
              : Stack(
                  children: [
                    //1. Capa de fondo: El mapa de Google.
                    GoogleMap(
                      onMapCreated: (controller) => _mapController = controller,
                      initialCameraPosition: CameraPosition(
                        target: LatLng(_posicionActual!.latitude, _posicionActual!.longitude),
                        zoom: 10.0, //Un zoom ideal para ver la isla completa.
                      ),
                      markers: _marcadores, //Le pasamos la lista de chinchetas.
                      myLocationEnabled: true, //Muestra el punto azul nativo de Google.
                      myLocationButtonEnabled: true, //Botón para centrar la cámara en nosotros.
                      mapToolbarEnabled: false,
                      zoomControlsEnabled: false, //Quitamos los botones feos de + y - para un diseño más limpio.
                    ),
                    
                    //2. Capa superior: NUEVO botón para forzar la conexión saltando la seguridad.
                    Positioned(
                      bottom: 30, //A 30 píxeles desde abajo
                      left: 20,   //A 20 píxeles desde la izquierda
                      child: FloatingActionButton.extended(
                        heroTag: 'btn_seguridad_bypass',
                        backgroundColor: TaxiTheme.primaryDark,
                        icon: const Icon(Icons.satellite_alt, color: TaxiTheme.accentGold),
                        label: const Text(
                          'Forzar Conexión', 
                          style: TextStyle(color: TaxiTheme.surfaceWhite, fontWeight: FontWeight.bold)
                        ),
                        onPressed: () async {
                          //Al pulsar el botón, activamos la carga y ejecutamos la búsqueda directamente.
                          setState(() => _cargando = true);
                          await _buscarGasolineras();
                          if (mounted) setState(() => _cargando = false);
                        },
                      ),
                    ),
                  ],
                ),
    );
  }
}