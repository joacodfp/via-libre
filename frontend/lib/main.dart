import 'package:flutter/material.dart';

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

// ---- NAVEGACIÓN INFERIOR (TABS) ----
class NavegacionPrincipal extends StatefulWidget {
  const NavegacionPrincipal({super.key});

  @override
  State<NavegacionPrincipal> createState() => _NavegacionPrincipalState();
}

class _NavegacionPrincipalState extends State<NavegacionPrincipal> {
  int _indiceActual = 0;

  // Las tres pantallas de nuestra app
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

// ---- PANTALLA 1: PASAJERO DIARIO ----
class PantallaPasajero extends StatelessWidget {
  const PantallaPasajero({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('📍 Estación más cercana', style: TextStyle(color: Colors.white, fontSize: 18)),
        backgroundColor: Colors.blue.shade900,
        actions: [
          IconButton(icon: const Icon(Icons.search, color: Colors.white), onPressed: () {}),
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.blue.shade50,
            child: const Row(
              children: [
                Icon(Icons.location_on, color: Colors.blue),
                SizedBox(width: 8),
                Text('Lomas de Zamora (Detectado)', style: TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              children: const [
                TarjetaTren(destino: "Plaza Constitución", llegaEn: "2 min", estado: "A horario", colorEstado: Colors.green),
                TarjetaTren(destino: "Ezeiza", llegaEn: "12 min", estado: "Demorado", colorEstado: Colors.red),
                TarjetaTren(destino: "Alejandro Korn", llegaEn: "15 min", estado: "A horario", colorEstado: Colors.green),
              ],
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
      body: const Center(
        child: Text('Acá guardaremos tus viajes de todos los días.', style: TextStyle(fontSize: 16, color: Colors.grey)),
      ),
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
            const Text('Buscar material tractivo / rodante en servicio:', style: TextStyle(fontWeight: FontWeight.bold)),
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
            const Text('Alertas Activas', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            ListTile(
              tileColor: Colors.amber.shade50,
              leading: const Icon(Icons.notifications_active, color: Colors.amber),
              title: const Text('Locomotora A924'),
              subtitle: const Text('Notificar cuando inicie servicio.'),
              trailing: Switch(value: true, onChanged: (val){}),
            ),
          ],
        ),
      ),
    );
  }
}

// ---- WIDGET REUTILIZABLE: TARJETA DE TREN ----
class TarjetaTren extends StatelessWidget {
  final String destino;
  final String llegaEn;
  final String estado;
  final Color colorEstado;

  const TarjetaTren({super.key, required this.destino, required this.llegaEn, required this.estado, required this.colorEstado});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        leading: Icon(Icons.train, color: colorEstado, size: 40),
        title: Text(destino, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(estado, style: TextStyle(color: colorEstado, fontWeight: FontWeight.bold)),
        trailing: Text(llegaEn, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      ),
    );
  }
}
