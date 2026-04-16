import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Para copiar al portapapeles
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/foundation.dart' show kIsWeb; // Para detectar si es Web o móvil
import '../theme/app_theme.dart';

class AgendaContactos extends StatefulWidget {
  const AgendaContactos({super.key});

  @override
  State<AgendaContactos> createState() => _AgendaContactosState();
}

class _AgendaContactosState extends State<AgendaContactos> {
  final _supabase = Supabase.instance.client;
  final _nombreController = TextEditingController();
  final _telefonoController = TextEditingController(); // Controlador del campo "numero"
  final _formKey = GlobalKey<FormState>(); // Clave para validar el formulario

  bool _cargando = true;
  bool _mostrandoFormulario = false; //Hasta que el usuario pulse el botón para mostrar el formulario esta se mantiene en false
  List<dynamic> _contactos = []; //Lista de los contactos ya añadidos a la agenda, los trae el backend de Supabase

  bool get _esOrdenador => kIsWeb;   // Detectar si es ordenador (Web) para copiar en lugar de llamar

  @override
  void initState() { //Init de la pantalla, trayendo directamente los contactos guardados en la base de datos
    super.initState();
    _obtenerContactos();
  }

  @override
  void dispose() { //Este método sirve para liberar la cache de los controladores una vez se cierra la pantalla
    _nombreController.dispose();
    _telefonoController.dispose();
    super.dispose();
  }

  Future<void> _obtenerContactos() async { //Función para obtener los contactos guardados en la base de datos, ordenados por nombre
    setState(() => _cargando = true);
    try {
      final data = await _supabase.from('agenda').select().order('nombre');
      setState(() => _contactos = data);
    } catch (e) {
      _notificar("Error al cargar agenda", TaxiTheme.error);
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  Future<void> _gestionarAccion(String numero) async { //Este método lleva acabo una acción según la variable le diga que es Ordenador o Movil
    if (_esOrdenador) { //Si es ordenador, copiamos el número al portapapeles en lugar de intentar llamar
      await Clipboard.setData(ClipboardData(text: numero));
      _notificar("Número copiado al portapapeles", TaxiTheme.success);
    } else { //Si no es ordenador, intentamos lanzar la aplicación de teléfono para llamar al número
      final Uri launchUri = Uri(scheme: 'tel', path: numero);
      if (await canLaunchUrl(launchUri)) {
        await launchUrl(launchUri);
      } else {
        _notificar("No se puede realizar la llamada", TaxiTheme.error); //Si existe algún error se notifica al usuario
      }
    }
  }

  Future<void> _guardarContacto() async {
    if (!_formKey.currentState!.validate()) return; //Esta linea valida el formulario asegurando que los textFields no están vacíos o con datos erroneos antes de intentar guardar el contacto
    
    setState(() => _cargando = true);
    try {
      await _supabase.from('agenda').insert({ //Aquí se hace el insert a la tabla recogiendo lo que el usuario introduzca en los TextFields, y se le asigna a cada campo el valor correspondiente
        'nombre': _nombreController.text.trim(),
        'numero': _telefonoController.text.trim(), 
      });
      
      _nombreController.clear(); //Una vez guardado se limpian los campos para seguir introduciendo en caso que el user quiera
      _telefonoController.clear();
      setState(() => _mostrandoFormulario = false); //Cierra automáticamente el formulario una vez se guarda el contacto
      await _obtenerContactos(); //Abtiene de nuevo la lista de contactos para mostrar el nuevo contacto añadido sin necesidad de recargar la pantalla
      _notificar("Contacto guardado correctamente", TaxiTheme.success);
    } catch (e) {
      // Si falla, mostramos el error exacto para debugear
      _notificar("Error: ${e.toString()}", TaxiTheme.error); //Si sale todo bien se notifica en verde, si hay algún fallo sale en rojo
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  void _notificar(String msg, Color color) { //Función para notificar vía SnackBar cualquier mensaje, pasando por parámetro el mensaje y color deseado
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg), 
      backgroundColor: color,
      behavior: SnackBarBehavior.floating,
    ));
  }

  @override
  Widget build(BuildContext context) { //Widget principal simple, depende de la variable _mostrandoFormulario para mostrar la lista de contactos o el formulario de añadir nuevo contacto, y un botón flotante para mostrar el formulario
    return Scaffold(
      backgroundColor: TaxiTheme.backgroundLight,
      appBar: AppBar(
        title: const Text('AGENDA DE CONTACTOS', style: TaxiTheme.tituloAppBar), //El título esta siemrpe pero el botón para cerrar el formulario solo aparece si el formulario está abierto, para que el usuario pueda cerrarlo sin necesidad de guardar un contacto
        backgroundColor: TaxiTheme.primaryDark,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          if (_mostrandoFormulario)//Si el formulario se está mostrando, aparece un botón de cerrar en el AppBar para ocultar el formulario
            IconButton(
              icon: const Icon(Icons.close), 
              onPressed: () => setState(() => _mostrandoFormulario = false)
            )
        ],
      ),
      body: _mostrandoFormulario ? _buildFormulario() : _buildLista(), //Dependiendo de la variable _mostrandoFormulario se muestra la lista de contactos o el formulario para añadir nuevo contacto
      floatingActionButton: _mostrandoFormulario 
        ? null 
        : FloatingActionButton( //Si no se está mostrando el formulario, aparece un botón flotante para mostrar el formulario y añadir un nuevo contacto
            backgroundColor: TaxiTheme.accentGold,
            onPressed: () => setState(() => _mostrandoFormulario = true),
            child: const Icon(Icons.person_add, color: TaxiTheme.primaryDark),
          ),
    );
  }

  Widget _buildLista() { //Este widget construye el widget de la lista, para mostrarlo en caso de que _mostrarFormulario este en false
    if (_cargando) return const Center(child: CircularProgressIndicator(color: TaxiTheme.primaryDark));
    if (_contactos.isEmpty) return const Center(child: Text("No hay contactos guardados")); //Si no se encuentran contactos en la BBDD

    return ListView.builder( //Construimos la lista con la especificaciones de abajo
      padding: const EdgeInsets.all(20),
      itemCount: _contactos.length,
      itemBuilder: (context, index) {
        final c = _contactos[index]; //Iteramos la lista de _contactos y la guardamos en el final "c"
        final numFull = c['numero'].toString(); 

        return Container( //Construimos el container que tiene la decoración de la tarjeta de contacto
          margin: const EdgeInsets.only(bottom: 12),
          decoration: TaxiTheme.decoracionTarjeta,
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            leading: CircleAvatar( //Avatar para rellenar la presentación
              backgroundColor: TaxiTheme.primaryDark.withOpacity(0.1),
              child: const Icon(Icons.person, color: TaxiTheme.primaryDark),
            ),
            title: Text(
              c['nombre'].toString().toUpperCase(), //Se imprime el nombre del contacto en mayúsculas y con un estilo agenda
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 1)
            ),
            subtitle: Text(
              numFull, //Se imprime el numero de telefono parseado
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: TaxiTheme.success)
            ),
            trailing: IconButton(
              icon: Icon(_esOrdenador ? Icons.copy_rounded : Icons.phone_forwarded), //Detectando si estás en ordenador da un icono de copiar al portapapeles, y si no, un icono de un movil
              color: TaxiTheme.accentGold,
              onPressed: () => _gestionarAccion(numFull),
            ),
          ),
        );
      },
    );
  }

  Widget _buildFormulario() { //Widget para construir el formulario de añadir
    return Form(
      key: _formKey,
      child: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(25),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("NUEVO CONTACTO", style: TextStyle(fontWeight: FontWeight.bold, color: TaxiTheme.primaryDark)),
                  const SizedBox(height: 20),
                  _buildTextField(_nombreController, "Nombre completo", Icons.badge), //TextFields de nombre y numero, con sus respectivos controladores para recoger lo que el usuario introduzca
                  const SizedBox(height: 20),
                  _buildTextField(_telefonoController, "Número de teléfono", Icons.phone, keyboard: TextInputType.phone),
                  const SizedBox(height: 10),
                  const Text(
                    "Se guardará en la agenda común de la flota.", //Subtitulo
                    style: TextStyle(fontSize: 12, color: TaxiTheme.textSecondary, fontStyle: FontStyle.italic),
                  ),
                ],
              ),
            ),
          ),
          _buildBotonGuardarAbajo(), //Se invoca el botón de guardar 
        ],
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String hint, IconData icon, {TextInputType keyboard = TextInputType.text}) { //Widget que construye los textFields, recibe por parámetro el controlador, el hint, el icono y el tipo de teclado (por defecto texto, pero para el número se le asigna teclado numérico)
    return TextFormField(
      controller: controller,
      keyboardType: keyboard,
      style: const TextStyle(fontWeight: FontWeight.bold),
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: Icon(icon, color: TaxiTheme.primaryDark),
        filled: true,
        fillColor: TaxiTheme.surfaceWhite,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.withOpacity(0.1))),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: TaxiTheme.accentGold)),
      ),
      validator: (v) => v!.isEmpty ? "Este campo no puede estar vacío" : null, //Validación para asegurarse de que el campo correspondiente no esté vacío
    );
  }

  Widget _buildBotonGuardarAbajo() { //Este widget construye el botón de guardadao
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: TaxiTheme.surfaceWhite,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -5))],
      ),
      child: SizedBox(
        width: double.infinity,
        height: 55,
        child: ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: TaxiTheme.success, 
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
          ),
          onPressed: _cargando ? null : _guardarContacto, //Si está cargando, el botón se desactiva para evitar múltiples pulsaciones, si no, se activa y llama a la función de guardar contacto
          icon: _cargando 
            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
            : const Icon(Icons.save, color: Colors.white),
          label: Text(
            _cargando ? "PROCESANDO..." : "GUARDAR EN AGENDA", //El texto del botón cambia si esta cargando o no, para dar accesibilidad al usuario
            style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 16)
          ),
        ),
      ),
    );
  }
}