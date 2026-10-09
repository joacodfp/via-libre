import 'dart:async';
import 'package:flutter/material.dart';
import 'api.dart';
import 'estado.dart';

void main() {
  runApp(const ViaLibreApp());
}

class ViaLibreApp extends StatelessWidget {
  const ViaLibreApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Via Libre',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF0D47A1)),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF0D47A1),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      home: const Principal(),
    );
  }
}

class Principal extends StatefulWidget {
  const Principal({super.key});

  @override
  State<Principal> createState() => _PrincipalState();
}

class _PrincipalState extends State<Principal> {
  int _i = 0;

  @override
  void initState() {
    super.initState();
    Estado.i.cargarPreferencias();
  }

  @override
  Widget build(BuildContext context) {
    const pantallas = [PantallaCerca(), PantallaFavoritas(), PantallaSpotter()];
    return Scaffold(
      body: pantallas[_i],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _i,
        onDestinationSelected: (v) => setState(() => _i = v),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.near_me), label: 'Cerca'),
          NavigationDestination(icon: Icon(Icons.star), label: 'Favoritas'),
          NavigationDestination(icon: Icon(Icons.radar), label: 'Spotter'),
        ],
      ),
    );
  }
}

String _dist(double? m) {
  if (m == null) return '';
  return m < 1000 ? '${m.round()} m' : '${(m / 1000).toStringAsFixed(1)} km';
}

// ---------------- CERCA ----------------
class PantallaCerca extends StatefulWidget {
  const PantallaCerca({super.key});

  @override
  State<PantallaCerca> createState() => _PantallaCercaState();
}

class _PantallaCercaState extends State<PantallaCerca> {
  bool cargando = true;
  String? error;
  String filtro = '';

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    setState(() {
      cargando = true;
      error = null;
    });

    try {
      await Estado.i.actualizarCercanas();
    } catch (_) {
      error = 'No se pudieron cargar las estaciones. Revisa tu conexion.';
    }

    if (mounted) setState(() => cargando = false);
  }

  @override
  Widget build(BuildContext context) {
    final e = Estado.i;
    final lista = filtro.trim().isEmpty
        ? e.cercanas
        : e.todas
            .where((x) => x.nombre.toLowerCase().contains(filtro.trim().toLowerCase()))
            .take(30)
            .toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Estaciones cerca tuyo'),
        actions: [
          IconButton(onPressed: _cargar, icon: const Icon(Icons.my_location)),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Buscar estacion por nombre',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onChanged: (v) => setState(() => filtro = v),
            ),
          ),
          if (e.errorUbicacion != null && filtro.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                e.errorUbicacion!,
                style: const TextStyle(color: Colors.orange),
              ),
            ),
          if (error != null)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(error!),
            ),
          Expanded(
            child: cargando
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    itemCount: lista.length,
                    itemBuilder: (_, i) => ListTile(
                      leading: const Icon(Icons.train),
                      title: Text(lista[i].nombre),
                      trailing: Text(_dist(e.distanciaA(lista[i].id))),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => PantallaEstacion(lista[i]),
                        ),
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

// ---------------- FAVORITAS ----------------
class PantallaFavoritas extends StatelessWidget {
  const PantallaFavoritas({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mis estaciones')),
      body: ValueListenableBuilder<List<Estacion>>(
        valueListenable: Estado.i.favoritas,
        builder: (_, favs, __) {
          if (favs.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'Todavia no tenes favoritas. Abri una estacion y toca la estrella.',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          return ListView(
            children: favs
                .map(
                  (f) => ListTile(
                    leading: const Icon(Icons.star, color: Colors.amber),
                    title: Text(f.nombre),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => PantallaEstacion(f),
                      ),
                    ),
                  ),
                )
                .toList(),
          );
        },
      ),
    );
  }
}

// ---------------- ESTACION (arribos) ----------------
class PantallaEstacion extends StatefulWidget {
  final Estacion estacion;
  const PantallaEstacion(this.estacion, {super.key});

  @override
  State<PantallaEstacion> createState() => _PantallaEstacionState();
}

class _PantallaEstacionState extends State<PantallaEstacion> {
  List<Arribo> arribos = [];
  bool cargando = true;
  String? error;
  late final Timer _t;

  @override
  void initState() {
    super.initState();
    _cargar();
    _t = Timer.periodic(const Duration(seconds: 30), (_) => _cargar());
  }

  @override
  void dispose() {
    _t.cancel();
    super.dispose();
  }

  Future<void> _cargar() async {
    try {
      final r = await ApiTrenes.arribos(widget.estacion.id);
      if (mounted) {
        setState(() {
          arribos = r;
          cargando = false;
          error = null;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          cargando = false;
          error = 'No se pudo actualizar. Reintentando...';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.estacion.nombre),
        actions: [
          ValueListenableBuilder<List<Estacion>>(
            valueListenable: Estado.i.favoritas,
            builder: (_, __, ___) => IconButton(
              icon: Icon(
                Estado.i.esFavorita(widget.estacion.id)
                    ? Icons.star
                    : Icons.star_border,
              ),
              onPressed: () => Estado.i.alternarFavorita(widget.estacion),
            ),
          ),
        ],
      ),
      body: cargando
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _cargar,
              child: ListView(
                children: [
                  if (error != null)
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: Text(error!),
                    ),
                  if (arribos.isEmpty && error == null)
                    const Padding(
                      padding: EdgeInsets.all(24),
                      child: Text('No hay trenes proximos informados.'),
                    ),
                  ...arribos.map((a) => TarjetaArribo(a)),
                ],
              ),
            ),
    );
  }
}

class TarjetaArribo extends StatelessWidget {
  final Arribo a;
  const TarjetaArribo(this.a, {super.key});

  @override
  Widget build(BuildContext context) {
    Color color = Colors.green;
    String estadoTxt = 'En hora';

    if (a.cancelado) {
      color = Colors.red;
      estadoTxt = 'Cancelado';
    } else if (a.demorado) {
      color = Colors.red;
      estadoTxt = 'Demora ${(a.demoraSeg! / 60).round()} min';
    } else if (a.demoraSeg == null) {
      color = Colors.grey;
      estadoTxt = 'Programado';
    }

    final cuando = a.segundos <= 60 ? 'Llegando' : '${(a.segundos / 60).round()} min';

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'a ${a.destino}',
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Text(
                  cuando,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text('${a.linea} - ${a.ramal}', style: const TextStyle(fontSize: 12)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                Chip(
                  label: Text(estadoTxt, style: TextStyle(color: color)),
                  visualDensity: VisualDensity.compact,
                ),
                Chip(
                  avatar: const Icon(Icons.tag, size: 16),
                  label: Text('Servicio ${a.servicio}'),
                  visualDensity: VisualDensity.compact,
                ),
                Chip(
                  avatar: Icon(
                    a.electrico ? Icons.bolt : Icons.local_gas_station,
                    size: 16,
                  ),
                  label: Text('Formacion ${a.formacion ?? "sin asignar"}'),
                  visualDensity: VisualDensity.compact,
                ),
                if (a.anden != null)
                  Chip(
                    label: Text('Anden ${a.anden}'),
                    visualDensity: VisualDensity.compact,
                  ),
                if (a.enVivo)
                  const Chip(
                    avatar: Icon(Icons.gps_fixed, size: 16),
                    label: Text('GPS en vivo'),
                    visualDensity: VisualDensity.compact,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------- SPOTTER ----------------
class Hallazgo {
  final Arribo arribo;
  final Estacion estacion;
  Hallazgo(this.arribo, this.estacion);
}

class PantallaSpotter extends StatefulWidget {
  const PantallaSpotter({super.key});

  @override
  State<PantallaSpotter> createState() => _PantallaSpotterState();
}

class _PantallaSpotterState extends State<PantallaSpotter> {
  final _ctrl = TextEditingController();
  List<Hallazgo> resultados = [];
  Map<String, Hallazgo?> seguidas = {};
  bool buscando = false;
  String? consulta;
  late final Timer _t;

  @override
  void initState() {
    super.initState();
    _t = Timer.periodic(const Duration(seconds: 60), (_) => _revisarSeguidas());
    Estado.i.formacionesSeguidas.addListener(_revisarSeguidas);
    _revisarSeguidas();
  }

  @override
  void dispose() {
    _t.cancel();
    Estado.i.formacionesSeguidas.removeListener(_revisarSeguidas);
    _ctrl.dispose();
    super.dispose();
  }

  /// Estaciones donde buscamos: favoritas + las mas cercanas.
  List<Estacion> _estacionesAEscanear() {
    final m = <int, Estacion>{};
    for (final e in Estado.i.favoritas.value) {
      m[e.id] = e;
    }
    for (final e in Estado.i.cercanas.take(5)) {
      m[e.id] = e;
    }
    return m.values.toList();
  }

  Future<List<Hallazgo>> _escanear() async {
    final ests = _estacionesAEscanear();
    final grupos = await Future.wait(
      ests.map((e) async {
        try {
          final l = await ApiTrenes.arribos(e.id, cantidad: 10);
          return l.map((a) => Hallazgo(a, e)).toList();
        } catch (_) {
          return <Hallazgo>[];
        }
      }),
    );
    return grupos.expand((x) => x).toList();
  }

  Future<void> _buscar() async {
    final q = _ctrl.text.trim().toUpperCase();
    if (q.isEmpty) return;

    setState(() {
      buscando = true;
      consulta = q;
    });

    final todos = await _escanear();
    final vistos = <int>{};
    final r = todos
        .where((h) => (h.arribo.formacion ?? '').toUpperCase().contains(q))
        .where((h) => vistos.add(h.arribo.servicio))
        .toList();

    if (mounted) {
      setState(() {
        resultados = r;
        buscando = false;
      });
    }
  }

  Future<void> _revisarSeguidas() async {
    final lista = Estado.i.formacionesSeguidas.value;
    if (lista.isEmpty) {
      if (mounted) setState(() => seguidas = {});
      return;
    }

    final todos = await _escanear();
    final m = <String, Hallazgo?>{};
    for (final f in lista) {
      Hallazgo? h;
      for (final x in todos) {
        if ((x.arribo.formacion ?? '').toUpperCase() == f) {
          h = x;
          break;
        }
      }
      m[f] = h;
    }

    if (mounted) setState(() => seguidas = m);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Spotter - formaciones')),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          TextField(
            controller: _ctrl,
            textCapitalization: TextCapitalization.characters,
            onSubmitted: (_) => _buscar(),
            decoration: InputDecoration(
              hintText: 'Formacion o locomotora (ej: M23)',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: IconButton(
                icon: const Icon(Icons.arrow_forward),
                onPressed: _buscar,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Por ahora busca en tus estaciones favoritas y las 5 mas cercanas. '
            'La busqueda en toda la red llega en la proxima etapa.',
            style: TextStyle(fontSize: 12),
          ),
          const SizedBox(height: 12),
          if (buscando) const Center(child: CircularProgressIndicator()),
          if (!buscando && consulta != null && resultados.isEmpty)
            Text('No encontre "$consulta" circulando cerca de tus estaciones.'),
          ...resultados.map((h) => _tarjetaHallazgo(h)),
          if (consulta != null && resultados.isNotEmpty)
            Align(
              alignment: Alignment.centerLeft,
              child: ValueListenableBuilder<List<String>>(
                valueListenable: Estado.i.formacionesSeguidas,
                builder: (_, seg, __) => TextButton.icon(
                  onPressed: () => Estado.i.alternarFormacion(consulta!),
                  icon: Icon(
                    seg.contains(consulta)
                        ? Icons.notifications_off
                        : Icons.notifications_active,
                  ),
                  label: Text(
                    seg.contains(consulta)
                        ? 'Dejar de seguir $consulta'
                        : 'Seguir $consulta',
                  ),
                ),
              ),
            ),
          const Divider(height: 32),
          const Text(
            'Formaciones que sigo',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          ValueListenableBuilder<List<String>>(
            valueListenable: Estado.i.formacionesSeguidas,
            builder: (_, seg, __) {
              if (seg.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    'Busca una formacion y toca "Seguir" para vigilarla.',
                  ),
                );
              }

              return Column(
                children: seg.map((f) {
                  final h = seguidas[f];
                  return ListTile(
                    leading: Icon(
                      Icons.train,
                      color: h != null ? Colors.green : Colors.grey,
                    ),
                    title: Text(f),
                    subtitle: Text(
                      h == null
                          ? 'No la veo en tus estaciones ahora'
                          : 'Servicio ${h.arribo.servicio} a ${h.arribo.destino} - llega a ${h.estacion.nombre} en ${(h.arribo.segundos / 60).round()} min',
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Estado.i.alternarFormacion(f),
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _tarjetaHallazgo(Hallazgo h) {
    final a = h.arribo;
    return Card(
      child: ListTile(
        leading: Icon(a.electrico ? Icons.bolt : Icons.local_gas_station),
        title: Text('${a.formacion} - Servicio ${a.servicio}'),
        subtitle: Text(
          'a ${a.destino}\nLlega a ${h.estacion.nombre} en ${(a.segundos / 60).round()} min (${a.estado})'
          '${a.enVivo ? "\nGPS: ${a.lat!.toStringAsFixed(4)}, ${a.lon!.toStringAsFixed(4)}" : ""}',
        ),
        isThreeLine: true,
      ),
    );
  }
}
