import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'dart:ui';

import 'package:path_provider/path_provider.dart';

import '../config.dart';
import 'dibujo.dart';

/// Una mancha de pintura. Al tocar queda una mancha redonda (con el borde un
/// poquito ondulado) alrededor del dedo; si el dedo se arrastra, una franja
/// sigue al dedo.
class Trazo {
  Trazo({
    required this.color,
    required this.radio,
    required this.semilla,
    required Offset inicio,
  }) : puntos = <Offset>[inicio];

  Trazo._(this.color, this.radio, this.semilla, this.puntos);

  final Color color;

  /// Tamaño de la mancha (en unidades del dibujo).
  final double radio;

  /// Forma de la mancha. 0 = círculo perfecto (se usa cuando la mancha llena
  /// toda la zona de un toque); otro número = una mancha con bordes ondulados.
  final int semilla;

  /// Dónde tocó el dedo (el primero) y por dónde se arrastró (los demás).
  final List<Offset> puntos;

  Path? _mancha;
  Path? _franja;

  Offset get centro => puntos.first;

  double get anchoFranja => radio * Ajustes.anchoArrastre;

  Path get mancha => _mancha ??= _crearMancha(puntos.first, radio, semilla);

  /// El camino del arrastre, o null si fue solo un toque.
  Path? get franja {
    if (puntos.length < 2) return null;
    final existente = _franja;
    if (existente != null) return existente;
    final nueva = Path()..moveTo(puntos.first.dx, puntos.first.dy);
    for (var i = 1; i < puntos.length; i++) {
      nueva.lineTo(puntos[i].dx, puntos[i].dy);
    }
    _franja = nueva;
    return nueva;
  }

  /// Agrega un punto del arrastre (si se alejó lo suficiente del anterior).
  /// Devuelve true si se agregó.
  bool sumar(Offset punto) {
    if ((punto - puntos.last).distance < 6) return false;
    puntos.add(punto);
    _franja?.lineTo(punto.dx, punto.dy);
    return true;
  }

  static Path _crearMancha(Offset c, double r, int semilla) {
    if (semilla == 0) {
      return Path()..addOval(Rect.fromCircle(center: c, radius: r));
    }
    final azar = math.Random(semilla);
    final f1 = azar.nextDouble() * 2 * math.pi;
    final f2 = azar.nextDouble() * 2 * math.pi;
    final f3 = azar.nextDouble() * 2 * math.pi;
    const lados = 48;
    final forma = Path();
    for (var i = 0; i < lados; i++) {
      final a = i * 2 * math.pi / lados;
      final rr = r *
          (0.92 +
              0.06 * math.sin(3 * a + f1) +
              0.04 * math.sin(5 * a + f2) +
              0.03 * math.sin(7 * a + f3));
      final x = c.dx + rr * math.cos(a);
      final y = c.dy + rr * math.sin(a);
      if (i == 0) {
        forma.moveTo(x, y);
      } else {
        forma.lineTo(x, y);
      }
    }
    forma.close();
    return forma;
  }

  static double _redondear(double v) => (v * 10).roundToDouble() / 10;

  Map<String, Object> aJson() {
    final p = <double>[];
    for (final punto in puntos) {
      p
        ..add(_redondear(punto.dx))
        ..add(_redondear(punto.dy));
    }
    return <String, Object>{
      'c': color.toARGB32(),
      'r': _redondear(radio),
      's': semilla,
      'p': p,
    };
  }

  /// Lee un trazo guardado. Devuelve null si los datos no sirven.
  static Trazo? desdeJson(Object? datos) {
    if (datos is! Map) return null;
    final c = datos['c'];
    final r = datos['r'];
    final s = datos['s'];
    final p = datos['p'];
    if (c is! int || r is! num || s is! int || p is! List || p.length < 2) {
      return null;
    }
    final puntos = <Offset>[];
    for (var i = 0; i + 1 < p.length; i += 2) {
      final x = p[i];
      final y = p[i + 1];
      if (x is! num || y is! num) return null;
      puntos.add(Offset(x.toDouble(), y.toDouble()));
    }
    return Trazo._(Color(c), r.toDouble(), s, puntos);
  }
}

/// Lo que se ha pintado de cada dibujo. Para cada dibujo hay una lista de
/// trazos por región.
///
/// Se guarda en el celular (un archivo por dibujo), así que lo pintado sigue
/// ahí aunque se cierre la app. Se guarda solo: un ratito después de levantar
/// el dedo, al salir de un dibujo y cuando la app se va a segundo plano.
class Pintura {
  Pintura._();

  static final Map<String, List<List<Trazo>>> _datos =
      <String, List<List<Trazo>>>{};
  static final Map<String, Dibujo> _dibujos = <String, Dibujo>{};
  static final Set<String> _pendientes = <String>{};
  static Timer? _temporizador;
  static Future<Directory?>? _carpeta;

  /// Las escrituras se hacen una detrás de otra para que no se pisen.
  static Future<void> _cola = Future<void>.value();

  static List<List<Trazo>> de(Dibujo dibujo) {
    _dibujos[dibujo.id] = dibujo;
    final actual = _datos[dibujo.id];
    if (actual != null && actual.length == dibujo.regiones.length) {
      return actual;
    }
    final nuevo = List<List<Trazo>>.generate(
      dibujo.regiones.length,
      (_) => <Trazo>[],
    );
    _datos[dibujo.id] = nuevo;
    return nuevo;
  }

  /// Lee del celular lo pintado de estos dibujos (solo los que todavía no
  /// están en memoria). Nunca lanza errores: si algo falla, el dibujo queda
  /// en blanco.
  static Future<void> cargar(List<Dibujo> dibujos) async {
    final carpeta = await _obtenerCarpeta();
    if (carpeta == null) return;
    await Future.wait(
      dibujos
          .where((d) => !_datos.containsKey(d.id))
          .map((d) => _cargarUno(carpeta, d)),
    );
  }

  static Future<void> _cargarUno(Directory carpeta, Dibujo dibujo) async {
    try {
      final archivo = File(_ruta(carpeta, dibujo.id));
      if (!await archivo.exists()) return;
      final datos = jsonDecode(await archivo.readAsString());
      if (datos is! Map) return;
      final regiones = datos['regiones'];
      if (regiones is! Map) return;
      if (_datos.containsKey(dibujo.id)) return; // ya se empezó a pintar
      final lista = de(dibujo);
      for (var i = 0; i < dibujo.regiones.length; i++) {
        final guardados = regiones[dibujo.regiones[i].id];
        if (guardados is! List) continue;
        for (final t in guardados) {
          final trazo = Trazo.desdeJson(t);
          if (trazo != null) lista[i].add(trazo);
        }
      }
    } catch (_) {
      // Un archivo dañado no debe impedir que se abra la app.
    }
  }

  /// Avisa que el dibujo cambió. Se guarda un ratito después (si sigue
  /// pintando, se espera a que pare).
  static void marcarCambio(Dibujo dibujo) {
    _dibujos[dibujo.id] = dibujo;
    _pendientes.add(dibujo.id);
    _temporizador?.cancel();
    _temporizador = Timer(const Duration(milliseconds: 800), guardarPendientes);
  }

  /// Guarda ya mismo todo lo que cambió.
  static Future<void> guardarPendientes() {
    _temporizador?.cancel();
    _temporizador = null;
    if (_pendientes.isEmpty) return _cola;
    final ids = _pendientes.toList();
    _pendientes.clear();
    final contenidos = <String, String>{};
    for (final id in ids) {
      final dibujo = _dibujos[id];
      final lista = _datos[id];
      if (dibujo == null || lista == null) continue;
      final regiones = <String, Object>{};
      for (var i = 0; i < dibujo.regiones.length && i < lista.length; i++) {
        if (lista[i].isEmpty) continue;
        regiones[dibujo.regiones[i].id] =
            lista[i].map((t) => t.aJson()).toList();
      }
      contenidos[id] = jsonEncode(<String, Object>{'v': 1, 'regiones': regiones});
    }
    return _enCola((carpeta) async {
      for (final entrada in contenidos.entries) {
        final ruta = _ruta(carpeta, entrada.key);
        final temporal = File('$ruta.tmp');
        await temporal.writeAsString(entrada.value, flush: true);
        await temporal.rename(ruta);
      }
    });
  }

  static void borrar(Dibujo dibujo) => borrarId(dibujo.id);

  /// Deja el dibujo en blanco y borra lo guardado en el celular.
  static void borrarId(String id) {
    _datos.remove(id);
    _pendientes.remove(id);
    _enCola((carpeta) async {
      final archivo = File(_ruta(carpeta, id));
      if (await archivo.exists()) await archivo.delete();
    });
  }

  static Future<void> _enCola(Future<void> Function(Directory) tarea) {
    _cola = _cola.then((_) async {
      try {
        final carpeta = await _obtenerCarpeta();
        if (carpeta != null) await tarea(carpeta);
      } catch (_) {
        // Si no se pudo guardar, se sigue pintando igual.
      }
    });
    return _cola;
  }

  static Future<Directory?> _obtenerCarpeta() {
    return _carpeta ??= () async {
      try {
        final base = await getApplicationSupportDirectory();
        final carpeta = Directory('${base.path}${Platform.pathSeparator}pintura');
        await carpeta.create(recursive: true);
        return carpeta;
      } catch (_) {
        return null;
      }
    }();
  }

  static String _ruta(Directory carpeta, String id) {
    final limpio = id.replaceAll(RegExp(r'[^A-Za-z0-9_\-]'), '_');
    return '${carpeta.path}${Platform.pathSeparator}$limpio.json';
  }
}
