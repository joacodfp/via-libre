import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';

void main() {
  runApp(const ViaLibreApp());
}

class ViaLibreApp extends StatelessWidget {
  const ViaLibreApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Vía Libre',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue.shade900),
        useMaterial3: true,
      ),
      home: const NavegacionPrincipal(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class NavegacionPrincipal extends StatefulWidget {
  const NavegacionPrincipal({super.key});

  @override
  State<NavegacionPrincipal> createState() => _NavegacionPrincipalState();
}

class _NavegacionPrincipalState extends State<NavegacionPrincipal> {
  int _indiceActual = 0;
  final List<Widget> _pantallas = [
    const PantallaPasajero(),
    const PantallaFavoritos(),
    const PantallaSpotter(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pantallas[_indiceActual],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _indiceActual,
        onDestinationSelected: (int index) {
          setState(() { _indiceActual = index; });
        },
        destinations: const [
          NavigationDestination(icon: Icon(Icons.train), label: 'Arribos'),
          NavigationDestination(icon: Icon(Icons.star), label: 'Favoritos'),
          NavigationDestination(icon: Icon(Icons.radar), label: 'Spotter'),
        ],
      ),
    );
  }
}

// ---- PANTALLA 1: ARRIBOS EN VIVO ----
class PantallaPasajero extends StatefulWidget {
  const PantallaPasajero({super.key});

  @override
  State<PantallaPasajero> createState() => _PantallaPasajeroState();
}

class _PantallaPasajeroState extends State<PantallaPasajero> {
  List<dynamic> trenesEnVivo = [];
  bool cargando = true;
  Timer? temporizador;

  @override
  void initState() {
    super.initState();
    buscarTrenes();
    // ¡Magia! Se actualiza solo cada 30 segundos
    temporizador = Timer.periodic(const Duration(seconds: 30), (Timer t) => buscarTrenes());
  }

  @override
  void dispose() {
    temporizador?.cancel();
    super.dispose();
  }

  Future<void> buscarTrenes() async {
    try {
      // 100 es el ID de ejemplo para una estación de la línea Roca. 
      // Más adelante haremos el buscador de estaciones.
      final url = Uri.parse('https://ariedro.dev/api-trenes/arribos/estacion/100');
      final respuesta = await http.get(url);

      if (respuesta.statusCode == 200) {
        setState(() {
          trenesEnVivo = json.decode(respuesta.body);
          cargando = false;
        });
      }
    } catch (e) {
      // Si el celular no tiene internet, mostramos algo vacío para no romper la app
      setState(() { cargando = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('📍 Estación en Vivo', style: TextStyle(color: Colors.white, fontSize: 18)),
        backgroundColor: Colors.blue.shade900,
      ),
      body: cargando 
        ? const Center(child: CircularProgressIndicator()) 
        : Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            color: Colors.blue.shade50,
            child: const Row(
              children: [
                Icon(Icons.wifi_tethering, color: Colors.blue),
                SizedBox(width: 8),
                Text('Conectado a la red de SOFSE', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: trenesEnVivo.length,
              itemBuilder: (context, index) {
                final tren = trenesEnVivo[index];
                
                // SOFSE devuelve "minutos", "destino", "estado" y "nombreTren" (Servicio)
                String destino = tren['destino'] ?? 'Desconocido';
                String minutos = tren['minutos']?.toString() ?? '--';
                String servicio = tren['nombreTren']?.toString() ?? 'N/A';
                String estado = tren['estado'] ?? 'En viaje';
                
                bool estaDemorado = estado.toLowerCase().contains('demora');

                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: ListTile(
                    leading: Icon(Icons.train, color: estaDemorado ? Colors.red : Colors.green, size: 40),
                    title: Text(destino, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(estado, style: TextStyle(color: estaDemorado ? Colors.red : Colors.green)),
                        const SizedBox(height: 4),
                        Text('Servicio: $servicio', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
                      ],
                    ),
                    trailing: Text('$minutos min', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
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

// ---- PANTALLA 2: FAVORITOS ----
class PantallaFavoritos extends StatelessWidget {
  const PantallaFavoritos({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mis Rutas', style: TextStyle(color: Colors.white)), backgroundColor: Colors.blue.shade900),
      body: const Center(child: Text('Tus viajes de todos los días.', style: TextStyle(color: Colors.grey))),
    );
  }
}

// ---- PANTALLA 3: FERROAFICIONADOS (SPOTTER) ----
class PantallaSpotter extends StatelessWidget {
  const PantallaSpotter({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Radar de Formaciones', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.blue.shade900,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Buscar material tractivo / rodante:', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            TextField(
              decoration: InputDecoration(
                hintText: 'Ej: CSR 05, GT22 A900...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                filled: true,
                fillColor: Colors.grey.shade100,
              ),
            ),
            const SizedBox(height: 20),
            const Text('Próxima Fase: El cruce de datos', style: TextStyle(fontSize: 16, color: Colors.blue)),
            const SizedBox(height: 10),
            const Text('En la siguiente actualización construiremos nuestra propia base de datos (Backend) para asociar los "Servicios" reales que ahora sí estamos recibiendo con los números físicos de chapa de cada formación.'),
          ],
        ),
      ),
    );
  }
}
