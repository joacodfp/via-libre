import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'api.dart';

class Estado {
  static final Estado i = Estado._();
  Estado._();

  List<Estacion> todas = [];
  List<Estacion> cercanas = [];
  String? errorUbicacion;

  final ValueNotifier<List<Estacion>> favoritas = ValueNotifier([]);
  final ValueNotifier<List<String>> formacionesSeguidas = ValueNotifier([]);

  Future<void> cargarPreferencias() async {
    final p = await SharedPreferences.getInstance();
    favoritas.value = (p.getStringList('favoritas') ?? [])
        .map((s) {
          final x = s.split('|');
          return Estacion(int.parse(x[0]), x[1], 0, 0);
        })
        .toList();
    formacionesSeguidas.value = p.getStringList('formaciones') ?? [];
  }

  bool esFavorita(int id) => favoritas.value.any((e) => e.id == id);

  Future<void> alternarFavorita(Estacion e) async {
    final l = [...favoritas.value];
    if (esFavorita(e.id)) {
      l.removeWhere((x) => x.id == e.id);
    } else {
      l.add(e);
    }
    favoritas.value = l;
    final p = await SharedPreferences.getInstance();
    await p.setStringList('favoritas', l.map((e) => '${e.id}|${e.nombre}').toList());
  }

  Future<void> alternarFormacion(String f) async {
    final l = [...formacionesSeguidas.value];
    final k = f.trim().toUpperCase();
    if (k.isEmpty) return;
    if (l.contains(k)) {
      l.remove(k);
    } else {
      l.add(k);
    }
    formacionesSeguidas.value = l;
    final p = await SharedPreferences.getInstance();
    await p.setStringList('formaciones', l);
  }

  Future<void> cargarEstaciones() async {
    if (todas.isEmpty) {
      print('[ViaLibre] cargando estaciones...');
      todas = await ApiTrenes.estaciones();
      print('[ViaLibre] estaciones cargadas: ${todas.length}');
    }
  }

  Future<void> actualizarCercanas() async {
    errorUbicacion = null;

    try {
      await cargarEstaciones();

      if (todas.isEmpty) {
        errorUbicacion = 'No se cargaron estaciones. Revisa tu conexión.';
        return;
      }

      try {
        var perm = await Geolocator.checkPermission();
        print('[ViaLibre] permiso inicial: $perm');

        if (perm == LocationPermission.denied) {
          perm = await Geolocator.requestPermission();
          print('[ViaLibre] permiso luego del request: $perm');
        }

        if (perm != LocationPermission.denied && perm != LocationPermission.deniedForever) {
          final pos = await Geolocator.getCurrentPosition(
            locationSettings: const LocationSettings(
              accuracy: LocationAccuracy.medium,
              timeLimit: Duration(seconds: 15),
            ),
          );

          final lista = todas.toList();
          double d(Estacion e) =>
              Geolocator.distanceBetween(pos.latitude, pos.longitude, e.lat, e.lon);

          lista.sort((a, b) => d(a).compareTo(d(b)));
          cercanas = lista.take(8).toList();
          _dist = {for (final e in cercanas) e.id: d(e)};
          return;
        }

        errorUbicacion = 'Sin permiso de ubicacion. Podes buscar tu estacion a mano.';
      } catch (_) {
        errorUbicacion = 'Sin ubicacion. Podes buscar manualmente.';
      }

      cercanas = todas.take(8).toList();
      _dist = {};
    } catch (e, st) {
      print('[ViaLibre] ERROR actualizarCercanas(): $e');
      print(st);
      errorUbicacion = 'No se pudo cargar la lista de estaciones.';
    }
  }

  Map<int, double> _dist = {};
  double? distanciaA(int id) => _dist[id];
}
