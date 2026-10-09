import 'dart:convert';
import 'package:http/http.dart' as http;

const String kBase = 'https://ariedro.dev/api-trenes';

Map<String, dynamic>? _m(dynamic v) => v is Map<String, dynamic> ? v : null;

class Estacion {
  final int id;
  final String nombre;
  final double lat;
  final double lon;
  Estacion(this.id, this.nombre, this.lat, this.lon);

  factory Estacion.fromJson(Map<String, dynamic> j) => Estacion(
        int.parse(j['id_estacion'].toString()),
        j['nombre'].toString(),
        double.tryParse(j['latitud'].toString()) ?? 0,
        double.tryParse(j['longitud'].toString()) ?? 0,
      );
}

class Arribo {
  final int servicio;
  final String ramal;
  final String linea;
  final String destino;
  final String? formacion; // ej: "M23" (puede ser null si aun no esta asignada)
  final bool electrico;
  final int segundos;
  final int? demoraSeg;
  final int toleranciaSeg;
  final String estado;
  final bool cancelado;
  final double? lat;
  final double? lon;
  final String? anden;

  Arribo({
    required this.servicio,
    required this.ramal,
    required this.linea,
    required this.destino,
    required this.formacion,
    required this.electrico,
    required this.segundos,
    required this.demoraSeg,
    required this.toleranciaSeg,
    required this.estado,
    required this.cancelado,
    required this.lat,
    required this.lon,
    required this.anden,
  });

  bool get demorado => demoraSeg != null && demoraSeg! > toleranciaSeg;
  bool get enVivo => lat != null && lon != null;

  factory Arribo.fromJson(Map<String, dynamic> j) {
    final a = _m(j['arribo']) ?? {};
    final s = _m(j['servicio']) ?? {};
    final ramal = _m(s['ramal']) ?? {};
    final hasta = _m(_m(j['hasta'])?['estacion']) ?? {};
    final eq = _m(s['equipo']) ?? _m(a['equipo']);
    final ll = _m(a['llegada']);
    final loc = _m(s['location']);

    int? demora;
    if (ll != null && ll['programada'] != null && ll['estimada'] != null) {
      try {
        demora = DateTime.parse(ll['estimada'].toString())
            .difference(DateTime.parse(ll['programada'].toString()))
            .inSeconds;
      } catch (_) {}
    }

    return Arribo(
      servicio: int.tryParse(s['numero'].toString()) ?? 0,
      ramal: (ramal['nombre'] ?? '').toString(),
      linea: (_m(s['gerencia'])?['nombre'] ?? '').toString(),
      destino: (hasta['nombre'] ?? _m(ramal['cabeceraFinal'])?['nombre'] ?? '?').toString(),
      formacion: eq?['nombre']?.toString(),
      electrico: eq?['esElectrico'] == 1,
      segundos: (a['segundos'] as num?)?.toInt() ?? 0,
      demoraSeg: demora,
      toleranciaSeg: (ramal['tolerancia'] as num?)?.toInt() ?? 300,
      estado: (_m(s['estado'])?['nombre'] ?? 'Programado').toString(),
      cancelado: s['cancelacion'] != null,
      lat: (loc?['lat'] as num?)?.toDouble(),
      lon: (loc?['long'] as num?)?.toDouble(),
      anden: _m(a['anden'])?['nombre']?.toString(),
    );
  }
}

class ApiTrenes {
  static Future<List<Estacion>> estaciones() async {
    final r = await http.get(Uri.parse('$kBase/infraestructura/estaciones'));
    if (r.statusCode != 200) throw Exception('Error ${r.statusCode}');
    final list = json.decode(r.body) as List;
    final vistos = <int>{};
    final out = <Estacion>[];
    for (final e in list) {
      final est = Estacion.fromJson(e as Map<String, dynamic>);
      if (est.lat != 0 && vistos.add(est.id)) out.add(est);
    }
    return out;
  }

  static Future<List<Arribo>> arribos(int idEstacion, {int cantidad = 8}) async {
    final r = await http
        .get(Uri.parse('$kBase/arribos/estacion/$idEstacion?cantidad=$cantidad'));
    if (r.statusCode != 200) throw Exception('Error ${r.statusCode}');
    final data = json.decode(r.body) as Map<String, dynamic>;
    final res = (data['results'] as List?) ?? [];
    return res
        .map((e) => Arribo.fromJson(e as Map<String, dynamic>))
        .where((a) => a.servicio != 0)
        .toList();
  }
}
