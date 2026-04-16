//Imports
import 'package:flutter/material.dart'; //Botones, colores, iconos...
import 'package:google_maps_flutter/google_maps_flutter.dart'; //Mapa de Google.
import 'package:geolocator/geolocator.dart';  //Localizador para saber donde estas
import '../theme/app_theme.dart'; //Colores y estilos.

//Pantalla
//Usamos un StatefulWidget porque esta pantalla va a cambiar.
//Va a empezar mostrando unas coordenadas fijas y luego se mueve.
class TraficoPage extends StatefulWidget {
  const TraficoPage({super.key});

  @override
  State<TraficoPage> createState() => _TraficoPageState();
}

class _TraficoPageState extends State<TraficoPage> {
  //Variables
  
  //MapController es el mando del mapa mos permitirá darle órdenes al mapa más adelante y la palabra 'late' es para darle un valor más tarde".
  late GoogleMapController mapController;
  
  //Coordenadas de respaldo (Gran Canaria) mientras le damos permisos al móvil para que busque nuestra ubicacion.
  final LatLng _centroPorDefecto = const LatLng(27.8153, -15.4453);

  //Arranque
  //initState es lo PRIMERO que se ejecuta antes de dibujar nada en pantalla.
  @override
  void initState() {
    super.initState();
    //Nada más abrir la pestaña de tráfico, activamos la función GPS.
    _obtenerUbicacionActual();
  }

  //Esta función se ejecuta sola cuando el mapa de Google termina de cargar es aquí donde vinculamos el mapController con el mapa real.
  void _onMapCreated(GoogleMapController controller) {
    mapController = controller;
  }

  //Logica
  //Esta función es 'async' (asincrona) porque buscar satélites y pedir permisos lleva tiempo el código tiene que esperar 'await' a que el usuario responda o el GPS reaccione.
  Future<void> _obtenerUbicacionActual() async {
    
    //Tiene el usuario el botón de Ubicación encendido en los ajustes de su móvil?.
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return; // Si lo tiene apagado, cancelamos.

    //Nos ha dado permiso a nuestra app para leer su ubicación?
    LocationPermission permission = await Geolocator.checkPermission();
    
    //Si la respuesta es que todavia no
    if (permission == LocationPermission.denied) {
      //Le preguntamos si nos da permiso
      permission = await Geolocator.requestPermission(); 
      
      //Si el usuario le da a que no en el cartelito, cancelamos.
      if (permission == LocationPermission.denied) return;
    }
    
    //Si el usuario nos bloqueó para siempre en el pasado, cancelamos.
    if (permission == LocationPermission.deniedForever) return;

    //Si llegamos aquí, tenemos permiso y el GPS está encendido.
    //Leemos las coordenadas exactas del taxista en ese momento.
    Position posicionActual = await Geolocator.getCurrentPosition();

    //Usamos nuestro mando para darle una orden al mapa.
    //AnimateCamera es una animacion a donde estemos y ponemos el zoom de la cámara en 15.0.
    mapController.animateCamera(
      CameraUpdate.newLatLngZoom(
        LatLng(posicionActual.latitude, posicionActual.longitude),
        15.0, 
      ),
    );
  }

  //Dibujar
  //El método build dibuja lo que ve el usuario.
  @override
  Widget build(BuildContext context) {
    //Scaffold es el "esqueleto" visual.
    return Scaffold(
      // ✅ 1. FONDO DINÁMICO
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      
      //La barra azul de arriba con el título. (Actualizado a paleta Premium)
      appBar: AppBar(
        backgroundColor: TaxiTheme.primaryDark,
        title: const Text('ESTADO DEL TRÁFICO', style: TaxiTheme.tituloAppBar),
        centerTitle: true, //Centramos el título.
        iconTheme: const IconThemeData(color: TaxiTheme.surfaceWhite),
        elevation: 0, //Quitamos la sombra para que se integre con el mapa.
      ),
      
      //El cuerpo de la pantalla el mapa de Google con el botón reposicionado.
      body: Stack(
        children: [
          GoogleMap(
            //Le pasamos la función que conecta el mando al crearse el mapa.
            onMapCreated: _onMapCreated,
            
            //Dónde debe mirar la cámara al abrir la pantalla.
            initialCameraPosition: CameraPosition(
              target: _centroPorDefecto,
              zoom: 14.0,
            ),
            
            //Activa las líneas rojas, naranjas y verdes de los atascos.
            trafficEnabled: true,
            
            //Círculo azul donde está el usuario.
            myLocationEnabled: true, 
            
            //Botón visual de la diana original porque da fallos en web.
            myLocationButtonEnabled: false, 
          ),

          //Posicionamos el botón arriba a la derecha para que no pise los mandos del mapa.
          Positioned(
            top: 15,
            right: 15,
            child: FloatingActionButton(
              backgroundColor: TaxiTheme.primaryDark,
              elevation: 6,
              onPressed: _obtenerUbicacionActual, //Al pulsar ejecuta la lógica del GPS
              child: const Icon(Icons.my_location, color: Colors.white), 
            ),
          ),
        ],
      ),
    );
  }
}