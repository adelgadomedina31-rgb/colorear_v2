import 'dart:convert';
import 'dart:ui';

import 'package:path_drawing/path_drawing.dart';

/// Una zona del dibujo que se puede pintar.
class Region {
  Region({required this.id, required this.path});

  final String id;
  final Path path;
}

/// Un adorno que no se pinta (ojos, sonrisas, perillas...).
class Detalle {
  Detalle({required this.path, this.relleno, this.grosor = 0});

  final Path path;

  /// Color de relleno; null = sin relleno.
  final Color? relleno;

  /// Grosor del trazo negro; 0 = sin trazo.
  final double grosor;
}

/// Un dibujo completo: regiones (se pintan) y detalles (solo decoran).
///
/// Formato JSON:
/// {
///   "id": "sol",            // texto único, sin espacios
///   "nombre": "Sol",
///   "lado": 1000,           // opcional; el dibujo es un cuadrado de lado x lado
///   "regiones": [ {"id": "cara", "path": "M 0 0 L 10 0 ... Z"} ],   // en orden: las últimas quedan encima
///   "detalles": [ {"path": "...", "relleno": "#000000", "grosor": 10} ]  // opcional
/// }
/// Los "path" son trazos SVG (M, L, C, Q, A, Z...).
class Dibujo {
  Dibujo({
    required this.id,
    required this.nombre,
    required this.lado,
    required this.regiones,
    required this.detalles,
    this.importado = false,
  });

  final String id;
  final String nombre;
  final double lado;
  final List<Region> regiones;
  final List<Detalle> detalles;

  /// true si lo agregó una persona desde la "Zona de papás".
  final bool importado;

  /// Áreas visibles ya calculadas (una por región).
  late final List<double?> _areas =
      List<double?>.filled(regiones.length, null);

  /// Área que se ve de la región [i] (en unidades²): la parte de la región
  /// que no queda tapada por las regiones de más arriba. Se calcula una sola
  /// vez, probando una cuadrícula de 20 x 20 puntos.
  double areaVisible(int i) {
    final guardada = _areas[i];
    if (guardada != null) return guardada;
    final forma = regiones[i].path;
    final caja = forma.getBounds();
    var area = 0.0;
    if (!caja.isEmpty) {
      const n = 20;
      var dentro = 0;
      for (var a = 0; a < n; a++) {
        for (var b = 0; b < n; b++) {
          final punto = Offset(
            caja.left + (a + 0.5) * caja.width / n,
            caja.top + (b + 0.5) * caja.height / n,
          );
          if (!forma.contains(punto)) continue;
          var tapado = false;
          for (var j = i + 1; j < regiones.length; j++) {
            if (regiones[j].path.contains(punto)) {
              tapado = true;
              break;
            }
          }
          if (!tapado) dentro++;
        }
      }
      area = caja.width * caja.height * dentro / (n * n);
    }
    _areas[i] = area;
    return area;
  }

  /// Lee un dibujo desde texto JSON. Si algo está mal lanza una
  /// FormatException con un mensaje que se puede mostrar tal cual.
  static Dibujo desdeTexto(String texto, {bool importado = false}) {
    Object? datos;
    try {
      datos = jsonDecode(texto);
    } on FormatException {
      throw const FormatException(
          'El texto no está completo o no tiene el formato correcto. '
          'Vuelve a copiarlo entero, de principio a fin.');
    }
    if (datos is! Map<String, dynamic>) {
      throw const FormatException(
          'Esto no parece un dibujo. Debe empezar con { y terminar con }.');
    }
    try {
      return Dibujo.fromJson(datos, importado: importado);
    } on FormatException {
      rethrow;
    } catch (_) {
      throw const FormatException(
          'El dibujo tiene datos que no entiendo. Revisa que esté completo.');
    }
  }

  factory Dibujo.fromJson(Map<String, dynamic> json, {bool importado = false}) {
    final id = json['id'];
    if (id is! String || id.trim().isEmpty) {
      throw const FormatException(
          'Falta el campo "id" (un texto corto y único, por ejemplo "gato").');
    }
    final nombreCrudo = json['nombre'];
    final nombre = (nombreCrudo is String && nombreCrudo.trim().isNotEmpty)
        ? nombreCrudo
        : id;

    final ladoCrudo = json['lado'];
    final lado = (ladoCrudo is num && ladoCrudo > 0) ? ladoCrudo.toDouble() : 1000.0;

    final listaRegiones = json['regiones'];
    if (listaRegiones is! List || listaRegiones.isEmpty) {
      throw const FormatException('Falta la lista "regiones" del dibujo.');
    }
    final regiones = <Region>[];
    final idsUsados = <String>{};
    for (var i = 0; i < listaRegiones.length; i++) {
      final r = listaRegiones[i];
      if (r is! Map<String, dynamic> || r['path'] is! String) {
        throw FormatException('La región ${i + 1} no tiene su "path".');
      }
      // Cada región necesita un id distinto (con él se guarda lo pintado).
      var idRegion = '${r['id'] ?? i}';
      if (!idsUsados.add(idRegion)) {
        idRegion = '${idRegion}_$i';
        idsUsados.add(idRegion);
      }
      regiones.add(Region(
        id: idRegion,
        path: _leerPath(r['path'] as String, 'la región ${i + 1}'),
      ));
    }

    final detalles = <Detalle>[];
    final listaDetalles = json['detalles'];
    if (listaDetalles is List) {
      for (var i = 0; i < listaDetalles.length; i++) {
        final d = listaDetalles[i];
        if (d is! Map<String, dynamic> || d['path'] is! String) {
          throw FormatException('El detalle ${i + 1} no tiene su "path".');
        }
        final grosorCrudo = d['grosor'];
        detalles.add(Detalle(
          path: _leerPath(d['path'] as String, 'el detalle ${i + 1}'),
          relleno: _leerColor(d['relleno']),
          grosor: grosorCrudo is num ? grosorCrudo.toDouble() : 0,
        ));
      }
    }

    return Dibujo(
      id: id.trim(),
      nombre: nombre,
      lado: lado,
      regiones: regiones,
      detalles: detalles,
      importado: importado,
    );
  }

  static Path _leerPath(String d, String donde) {
    try {
      return parseSvgPathData(d);
    } catch (_) {
      throw FormatException('El trazo de $donde no es válido.');
    }
  }

  static Color? _leerColor(Object? valor) {
    if (valor is! String) return null;
    final limpio = valor.trim().replaceFirst('#', '');
    if (!RegExp(r'^[0-9a-fA-F]{6}$').hasMatch(limpio)) return null;
    return Color(int.parse('FF$limpio', radix: 16));
  }
}
