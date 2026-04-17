import 'dart:convert'; //Para descifrar los datos que nos envía Google (JSON).
import 'dart:ui' as ui; //Para dibujar el icono de Material en un lienzo digital.
import 'dart:typed_data'; //Para transformar el dibujo en datos legibles por el mapa.
import 'package:flutter/material.dart'; //Botones, colores, iconos...
import 'package:google_maps_flutter/google_maps_flutter.dart'; //Para dibujar el mapa de Google.
import 'package:geolocator/geolocator.dart'; //Para saber dónde está el taxista.
import 'package:http/http.dart' as http; //Para hacer peticiones a Internet (a la API de Google).
import '../theme/app_theme.dart'; //Colores y estilos corporativos.


class EstacionesPage extends StatefulWidget { //StatefulWidget porque la pantalla cambiará: primero carga la ubicación y luego muestra el mapa con los marcadores.
  const EstacionesPage({super.key});

  @override
  State<EstacionesPage> createState() => _EstacionesPageState(); 
}

class _EstacionesPageState extends State<EstacionesPage> {

  // ignore: unused_field
  GoogleMapController? _mapController; //Controlador del mapa para poder mover la cámara.
  
  final Set<Marker> _marcadores = {}; //Lista de chinchetas que pondremos en el mapa.
  
  Position? _posicionActual;  //Para guardar la posición exacta del dispositivo (latitud y longitud).
  
  bool _cargando = true; //Círculo de carga mientras buscamos el GPS y descargamos los datos.

  BitmapDescriptor? _iconoGasolinera; //Para guardar nuestro icono personalizado.

  final String _apiKey = 'AIzaSyBCrZCJ6vqIt_9A01MsPShOeC0OXVHC8C0'; //Clave de la API de Google

  @override
  void initState() {
    super.initState();
    _cargarIcono().then((_) => _iniciarMapa()); //Nada más abrir la pantalla, cargamos el icono, buscamos dónde estamos y las gasolineras.
  }

  Future<void> _cargarIcono() async {  //Dibuja el icono del Material y lo convierte en un marcador de mapa.
    final ui.PictureRecorder pictureRecorder = ui.PictureRecorder();
    final Canvas canvas = Canvas(pictureRecorder);
    const double size = 40.0; // Tamaño del icono en el mapa

    final TextPainter textPainter = TextPainter( // Dibujamos el icono de Material
      textDirection: TextDirection.ltr,
    );
    textPainter.text = TextSpan(
      text: String.fromCharCode(Icons.local_gas_station.codePoint),
      style: TextStyle(
        fontSize: size,
        fontFamily: Icons.local_gas_station.fontFamily, //Usamos el molde del icono de gasolinera que ya existe en Flutter para asegurarnos de que se vea bien
        color: TaxiTheme.accentGold, 
      ),
    );
    textPainter.layout(); // Layout es necesario para que el TextPainter calcule el tamaño del texto antes de dibujarlo.
    textPainter.paint(canvas, const Offset(0.0, 0.0));

    final ui.Image image = await pictureRecorder.endRecording().toImage(size.toInt(), size.toInt()); // Convertimos el dibujo a una imagen que Google Maps entienda
    final ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    final Uint8List uint8List = byteData!.buffer.asUint8List();

    _iconoGasolinera = BitmapDescriptor.fromBytes(uint8List); //Guardamos el icono
  }
  Future<void> _iniciarMapa() async {   //Función principal que agrupa pedir permisos, buscar ubicación y buscar estaciones.
    try {
      await _obtenerUbicacion();
      if (_posicionActual != null) { //Si el usuario da su ubicación se muestran las estaciones cercanas más importantes, si no, se queda en la pantalla de error.
        await _buscarGasolineras();
      }
    } catch (e) {
      debugPrint("Error al iniciar el mapa: $e");
    } finally {
      if (mounted) {
        setState(() => _cargando = false); //Pase lo que pase, quitamos el círculo de carga para no bloquear la pantalla.
      }
    }
  }

  Future<void> _obtenerUbicacion() async { //Función asíncrona para pedir permiso de GPS y obtener las coordenadas.
    bool servicioHabilitado = await Geolocator.isLocationServiceEnabled();
    if (!servicioHabilitado) return;

    LocationPermission permiso = await Geolocator.checkPermission();
    if (permiso == LocationPermission.denied) {
      permiso = await Geolocator.requestPermission();
      if (permiso == LocationPermission.denied) return;
    }
    
    if (permiso == LocationPermission.deniedForever) return;

    _posicionActual = await Geolocator.getCurrentPosition(); //Si nos dan permiso, guardamos la latitud y longitud.
  }

  Future<void> _buscarGasolineras() async { //Función asíncrona para buscar gasolineras usando la API de Google Places.
    if (_posicionActual == null) return;

    final lat = _posicionActual!.latitude;
    final lng = _posicionActual!.longitude;
    final radioBuscado = 50000; // Buscamos en un radio de 50 km (máximo de Google) para abarcar toda la isla.

    final String urlGoogle = 
        'https://maps.googleapis.com/maps/api/place/nearbysearch/json' //Construimos la URL original de Google.
        '?location=$lat,$lng'
        '&radius=$radioBuscado'
        '&type=gas_station'
        '&key=$_apiKey';

    final String url = 'https://corsproxy.io/?${Uri.encodeComponent(urlGoogle)}'; //Codificamos la URL (Uri.encodeComponent) para que el proxy la envíe intacta sin perder la clave.

    try {
      final respuesta = await http.get(Uri.parse(url)); //Hacemos la llamada a Internet.

      if (respuesta.statusCode == 200) {
        final datos = json.decode(respuesta.body);
        final resultados = datos['results'] as List; //Google nos devuelve una lista de gasolineras en el campo 'results' que guardamos en "resultados"

        _marcadores.clear(); //Limpiamos los marcadores viejos.

        //Añadimos un marcador especial para nuestra ubicación actual.
        _marcadores.add(
          Marker(
            markerId: const MarkerId('mi_ubicacion'),
            position: LatLng(lat, lng),
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue), //Color azul para nosotros
            infoWindow: const InfoWindow(title: 'Mi Ubicación Actual'),
          ),
        );

        for (var lugar in resultados) {         //Recorremos la lista de gasolineras que nos devolvió Google y creamos una chincheta para cada una.
          final ubicacionLugar = lugar['geometry']['location'];
          final latitudLugar = ubicacionLugar['lat'];
          final longitudLugar = ubicacionLugar['lng'];
          final nombreLugar = lugar['name'];

          _marcadores.add(
            Marker(
              markerId: MarkerId(lugar['place_id']),
              position: LatLng(latitudLugar, longitudLugar),
              icon: _iconoGasolinera ?? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange), //Usamos nuestro icono personalizado. Si por algún motivo falló al cargar, usamos el naranja por defecto.
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

  //El método build dibuja lo que ve el usuario en la pantalla.
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // ✅ 1. FONDO DINÁMICO
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('ESTACIONES DE SERVICIO', style: TaxiTheme.tituloAppBar),
        centerTitle: true, //Centramos el título.
        backgroundColor: TaxiTheme.primaryDark,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white), //Aseguramos que la flecha de volver sea blanca.
        actions: [
          //Botón de refrescar clásico en la barra superior.
          IconButton(
            icon: const Icon(Icons.refresh), //Dibujamos el icono de refrescar para iniciar el mapa de nuevo en caso de error o ubicación distinta
            onPressed: () {
              setState(() => _cargando = true);
              _iniciarMapa();
            },
          ),
        ],
      ),

      body: _cargando //Consultamos si la variable de carga es verdadera o falsa para mostrar el círculo de carga, el error o el mapa.
          ? const Center(child: CircularProgressIndicator(color: TaxiTheme.accentGold))
          //Si es falso y no tenemos posición, mostramos un error.
          : _posicionActual == null
              // ✅ 2. TEXTO DINÁMICO (Por si no hay ubicación, que el error se lea bien en modo oscuro)
              ? Center(child: Text("No se pudo obtener la ubicación", style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color)))
              //Si es falso y TENEMOS posición, usamos Stack para dibujar el mapa y poner botones encima.
              : Stack(
                  children: [
                    GoogleMap(
                      onMapCreated: (controller) => _mapController = controller, //Capa de fondo: El mapa de Google.
                      initialCameraPosition: CameraPosition(
                        target: LatLng(_posicionActual!.latitude, _posicionActual!.longitude),
                        zoom: 10.0, 
                      ),
                      markers: _marcadores, //Le pasamos la lista de chinchetas.
                      myLocationEnabled: true, 
                      myLocationButtonEnabled: true, //Botón para centrar la cámara en nosotros.
                      mapToolbarEnabled: false,
                      zoomControlsEnabled: false, //Quitamos los botones feos de + y - para un diseño más limpio.
                    ),

                    Positioned( //Capa superior: NUEVO botón para forzar la conexión saltando la seguridad
                      bottom: 30, 
                      left: 20,
                      child: FloatingActionButton.extended(
                        heroTag: 'btn_seguridad_bypass',
                        backgroundColor: TaxiTheme.primaryDark,
                        icon: const Icon(Icons.satellite_alt, color: TaxiTheme.accentGold),
                        label: const Text(
                          'Forzar Conexión', 
                          style: TextStyle(color: TaxiTheme.surfaceWhite, fontWeight: FontWeight.bold)
                        ),
                        onPressed: () async { //Al pulsar el botón, activamos la carga y ejecutamos la búsqueda directamente.
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