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
      ),
      home: const PantallaPrincipal(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class PantallaPrincipal extends StatefulWidget {
  const PantallaPrincipal({super.key});

  @override
  State<PantallaPrincipal> createState() => _PantallaPrincipalState();
}

class _PantallaPrincipalState extends State<PantallaPrincipal> {
  bool modoSpotter = false;
  
  // Datos simulados para probar que la app funciona visualmente
  List<dynamic> trenes = [
    {"destino": "Plaza Constitución", "llegada": "2 min", "demora": 0, "servicio": "3042", "chapa": "CSR 05"},
    {"destino": "Ezeiza", "llegada": "15 min", "demora": 12, "servicio": "3046", "chapa": "Toshiba 18"}
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('📍 Lomas de Zamora', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.blue.shade900,
        actions: [
          Row(
            children: [
              const Icon(Icons.camera_alt, color: Colors.white, size: 18),
              Switch(
                value: modoSpotter,
                activeColor: Colors.amber,
                onChanged: (bool value) {
                  setState(() { modoSpotter = value; });
                },
              ),
            ],
          )
        ],
      ),
      body: ListView.builder(
        itemCount: trenes.length,
        itemBuilder: (context, index) {
          final tren = trenes[index];
          return Card(
            margin: const EdgeInsets.all(8),
            child: ListTile(
              leading: Icon(Icons.train, color: tren['demora'] > 0 ? Colors.red : Colors.green, size: 40),
              title: Text(tren['destino'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Llega en: ${tren['llegada']}'),
                  if (modoSpotter) ...[
                    const SizedBox(height: 5),
                    Text('Servicio: ${tren['servicio']} | Equipo: ${tren['chapa']}', 
                      style: const TextStyle(backgroundColor: Colors.amber, color: Colors.black, fontWeight: FontWeight.bold)),
                  ]
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}