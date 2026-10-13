import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui';

import 'package:flutter/foundation.dart' show ValueNotifier;
import 'package:path_provider/path_provider.dart';

import '../config.dart';
import 'dibujo.dart';

/// Una mancha de pintura. Al tocar queda una mancha que se "derrama" desde el
/// dedo; si el dedo se arrastra, una franja sigue al dedo.
///
/// Las manchas solo existen como formas mientras se están pintando. Cuando
/// terminan, se "hornean" dentro de la imagen del dibujo (ver [Pintura]), así
/// la app no se pone lenta aunque se pinte muchísimo.
class Trazo {
  Trazo({
    required this.region,
    required this.color,
    required this.radio,
    required this.semilla,
    required Offset inicio,
  }) : puntos = <Offset>[inicio];

  Trazo._(this.region, this.color, this.radio, this.semilla, this.puntos);

  /// Índice de la zona del dibujo donde se pinta.
  final int region;

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

  /// La forma final de la mancha (ya derramada).
  Path get mancha => _mancha ??= formaMancha(puntos.first, radio, semilla, 1.0);

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

  /// Rectángulo que contiene toda la pintura de este trazo.
  Rect limites() {
    var caja = Rect.fromCircle(
      center: puntos.first,
      radius: radio * (semilla == 0 ? 1.02 : 1.45),
    );
    final camino = franja;
    if (camino != null) {
      caja = caja.expandToInclude(camino.getBounds().inflate(anchoFranja / 2 + 2));
    }
    return caja;
  }

  /// Forma de una mancha mientras se "derrama".
  /// [avance] va de 0 (recién tocada) a 1 (tamaño final): la mancha crece
  /// desde el dedo, con el borde ondulándose como pintura líquida, y al final
  /// aparecen unas gotitas salpicadas alrededor.
  static Path formaMancha(Offset c, double r, int semilla, double avance) {
    final t = avance.clamp(0.0, 1.0).toDouble();
    // Crece rápido al principio y se frena al final (como un líquido).
    final crecido = 1 - math.pow(1 - t, 3).toDouble();
    final escala = 0.15 + 0.85 * crecido;
    if (semilla == 0) {
      return Path()..addOval(Rect.fromCircle(center: c, radius: r * escala));
    }
    final azar = math.Random(semilla);
    final f1 = azar.nextDouble() * 2 * math.pi;
    final f2 = azar.nextDouble() * 2 * math.pi;
    final f3 = azar.nextDouble() * 2 * math.pi;
    // Mientras se derrama, el borde se mueve y ondula más.
    final ondas = 1.0 + 0.9 * (1 - t);
    final giro = 1.4 * (1 - t);
    final rr0 = r * escala;
    const lados = 48;
    final forma = Path();
    for (var i = 0; i < lados; i++) {
      final a = i * 2 * math.pi / lados;
      final rr = rr0 *
          (0.92 +
              ondas *
                  (0.06 * math.sin(3 * a + f1 + giro) +
                      0.04 * math.sin(5 * a + f2 - giro) +
                      0.03 * math.sin(7 * a + f3 + 2 * giro)));
      final x = c.dx + rr * math.cos(a);
      final y = c.dy + rr * math.sin(a);
      if (i == 0) {
        forma.moveTo(x, y);
      } else {
        forma.lineTo(x, y);
      }
    }
    forma.close();
    // Gotitas salpicadas (aparecen en la segunda mitad del derrame).
    final gotas = 3 + azar.nextInt(3);
    final aparicion = ((t - 0.45) / 0.55).clamp(0.0, 1.0).toDouble();
    for (var g = 0; g < gotas; g++) {
      final a = azar.nextDouble() * 2 * math.pi;
      final distancia = r * (1.02 + azar.nextDouble() * 0.2);
      final tamano = r * (0.06 + azar.nextDouble() * 0.07);
      if (aparicion <= 0) continue;
      final centro = Offset(
        c.dx + distancia * escala * math.cos(a),
        c.dy + distancia * escala * math.sin(a),
      );
      forma.addOval(Rect.fromCircle(center: centro, radius: tamano * aparicion));
    }
    return forma;
  }

  /// Lee un trazo guardado por las versiones 3 y 4 de la app (se usa solo
  /// para pasar lo pintado al formato nuevo). Devuelve null si no sirve.
  static Trazo? desdeJson(Object? datos, int region) {
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
    return Trazo._(region, Color(c), r.toDouble(), s, puntos);
  }
}

/// Funciones de dibujo que comparten el lienzo, las miniaturas y el guardado.
class Dibujante {
  Dibujante._();

  static final Paint _capa = Paint();
  static final Paint _borrar = Paint()..blendMode = BlendMode.dstOut;
  static final Paint _suave = Paint()..filterQuality = FilterQuality.medium;

  /// Dibuja la mancha [t] (con su [avance]) solo en la parte visible de su
  /// zona: se recorta a la zona y se borra lo que tapan las zonas de encima.
  /// El canvas debe estar en unidades del dibujo.
  static void trazo(Canvas canvas, Dibujo d, Trazo t, double avance) {
    final i = t.region;
    if (i < 0 || i >= d.regiones.length) return;
    final caja = t.limites();
    canvas.saveLayer(caja, _capa);
    canvas.save();
    canvas.clipPath(d.regiones[i].path);
    final relleno = Paint()
      ..color = t.color
      ..style = PaintingStyle.fill;
    canvas.drawPath(
      avance >= 1.0
          ? t.mancha
          : Trazo.formaMancha(t.centro, t.radio, t.semilla, avance),
      relleno,
    );
    final camino = t.franja;
    if (camino != null) {
      canvas.drawPath(
        camino,
        Paint()
          ..color = t.color
          ..style = PaintingStyle.stroke
          ..strokeWidth = t.anchoFranja
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round,
      );
    }
    canvas.restore();
    for (var j = i + 1; d.capas && j < d.regiones.length; j++) {
      if (d.limites(j).overlaps(caja)) {
        canvas.drawPath(d.regiones[j].path, _borrar);
      }
    }
    canvas.restore();
  }

  /// Imagen con solo las líneas negras del dibujo (las que se ven) y los
  /// adornos; el resto es transparente. Se pone encima de la pintura.
  static Image lineas(Dibujo d, int px) {
    final grabadora = PictureRecorder();
    final canvas = Canvas(grabadora);
    final escala = px / d.lado;
    canvas.scale(escala, escala);
    canvas.saveLayer(Rect.fromLTWH(0, 0, d.lado, d.lado), Paint());
    final limpiar = Paint()..blendMode = BlendMode.clear;
    final contorno = Paint()
      ..color = const Color(0xFF000000)
      ..style = PaintingStyle.stroke
      ..strokeWidth = Ajustes.grosorContorno
      ..strokeJoin = StrokeJoin.round
      ..strokeCap = StrokeCap.round;
    for (final region in d.regiones) {
      // Cada zona tapa las líneas de las zonas que tiene debajo.
      canvas.drawPath(region.path, limpiar);
      canvas.drawPath(region.path, contorno);
    }
    canvas.restore();
    final detalleRelleno = Paint()..style = PaintingStyle.fill;
    final detalleLinea = Paint()
      ..color = const Color(0xFF000000)
      ..style = PaintingStyle.stroke
      ..strokeJoin = StrokeJoin.round
      ..strokeCap = StrokeCap.round;
    for (final detalle in d.detalles) {
      final color = detalle.relleno;
      if (color != null) {
        detalleRelleno.color = color;
        canvas.drawPath(detalle.path, detalleRelleno);
      }
      if (detalle.grosor > 0) {
        detalleLinea.strokeWidth = detalle.grosor;
        canvas.drawPath(detalle.path, detalleLinea);
      }
    }
    return _aImagen(grabadora, px);
  }

  /// Nueva imagen de pintura: la [base] (si hay) más estos [trazos].
  static Image hornear(Image? base, Dibujo d, List<Trazo> trazos, int px) {
    final grabadora = PictureRecorder();
    final canvas = Canvas(grabadora);
    if (base != null) {
      canvas.drawImageRect(base, _rect(base), _cuadro(px), _suave);
    }
    final escala = px / d.lado;
    canvas.scale(escala, escala);
    for (final t in trazos) {
      trazo(canvas, d, t, 1.0);
    }
    return _aImagen(grabadora, px);
  }

  /// Copia "plana" de una imagen, del tamaño pedido. Se hace de verdad
  /// (no queda enlazada a la imagen original), así la original se puede
  /// soltar de la memoria.
  static Future<Image> copiaPlana(Image imagen, int px) async {
    final grabadora = PictureRecorder();
    final canvas = Canvas(grabadora);
    canvas.drawImageRect(imagen, _rect(imagen), _cuadro(px), _suave);
    final foto = grabadora.endRecording();
    try {
      return await foto.toImage(px, px);
    } finally {
      foto.dispose();
    }
  }

  static Rect _rect(Image i) =>
      Rect.fromLTWH(0, 0, i.width.toDouble(), i.height.toDouble());

  static Rect _cuadro(int px) =>
      Rect.fromLTWH(0, 0, px.toDouble(), px.toDouble());

  static Image _aImagen(PictureRecorder grabadora, int px) {
    final foto = grabadora.endRecording();
    final imagen = foto.toImageSync(px, px);
    foto.dispose();
    return imagen;
  }
}

/// Lo que se ha pintado de cada dibujo.
///
/// La pintura de cada dibujo es UNA imagen (de [resolucion] x [resolucion]),
/// no una lista de manchas: así pintar cuesta siempre lo mismo, aunque se
/// pinte durante horas. Se guarda en el celular como PNG (un archivo por
/// dibujo), un ratito después de pintar, al salir del dibujo y cuando la app
/// se va a segundo plano.
///
/// En memoria solo está la imagen grande del dibujo abierto; los demás se
/// guardan como miniaturas para el menú.
class Pintura {
  Pintura._();

  static const int resolucion = 1024;
  static const int resolucionMiniatura = 320;

  /// Cambia cuando cambia alguna imagen (el menú y el lienzo se redibujan).
  static final ValueNotifier<int> cambios = ValueNotifier<int>(0);

  static final Map<String, Image> _completas = <String, Image>{};
  static final Map<String, Image> _miniaturas = <String, Image>{};
  static final Map<String, Image> _lineasMini = <String, Image>{};
  static final Map<String, int> _abiertos = <String, int>{};
  static final Map<String, int> _versiones = <String, int>{};
  static final Set<String> _sucios = <String>{};
  static final Set<String> _revisados = <String>{};
  static Timer? _temporizador;
  static Future<Directory?>? _carpeta;

  /// Las lecturas y escrituras se hacen una detrás de otra para no pisarse.
  static Future<void> _cola = Future<void>.value();

  /// Imagen de pintura del dibujo abierto (null = todavía sin pintar).
  static Image? completa(String id) => _completas[id];

  static Image? miniatura(String id) => _miniaturas[id];

  /// Cambia cuando se borra lo pintado: así se ignoran manchas viejas.
  static int version(String id) => _versiones[id] ?? 0;

  /// Líneas del dibujo en tamaño miniatura (se crean una vez).
  /// Para los dibujos hechos desde una imagen se preparan en [cargar]; hasta
  /// entonces devuelve null.
  static Image? lineasMiniatura(Dibujo d) {
    final hecha = _lineasMini[d.id];
    if (hecha != null) return hecha;
    if (d.lineasPng != null) return null;
    final nueva = Dibujante.lineas(d, resolucionMiniatura);
    _lineasMini[d.id] = nueva;
    return nueva;
  }

  /// Lee la imagen de líneas de un dibujo hecho desde una imagen, del tamaño
  /// pedido. Devuelve null si no tiene o no se pudo leer.
  static Future<Image?> lineasDeImagen(Dibujo d, int px) async {
    final png = d.lineasPng;
    if (png == null) return null;
    try {
      final imagen = await _decodificar(png, px);
      if (imagen == null) d.lineasPng = null;
      return imagen;
    } catch (_) {
      // Imagen dañada: las líneas se dibujan a partir de las zonas.
      d.lineasPng = null;
      return null;
    }
  }

  /// Olvida las líneas guardadas de un dibujo (cuando se reemplaza).
  static void olvidarLineas(String id) {
    _lineasMini.remove(id)?.dispose();
  }

  /// Lee las miniaturas de lo pintado (solo las que faltan). Si encuentra
  /// pintura guardada por una versión anterior de la app, la convierte.
  /// Nunca lanza errores.
  static Future<void> cargar(List<Dibujo> dibujos) async {
    // Líneas de las miniaturas de los dibujos hechos desde una imagen.
    for (final d in dibujos) {
      if (d.lineasPng == null || _lineasMini.containsKey(d.id)) continue;
      final lineas = await lineasDeImagen(d, resolucionMiniatura);
      if (lineas == null) continue;
      _lineasMini.remove(d.id)?.dispose();
      _lineasMini[d.id] = lineas;
    }
    await _cola;
    final carpeta = await _obtenerCarpeta();
    if (carpeta == null) return;
    final pendientes = dibujos.where((d) => !_revisados.contains(d.id)).toList();
    for (final d in pendientes) {
      _revisados.add(d.id);
    }
    for (final d in pendientes) {
      await _cargarMiniatura(carpeta, d);
    }
    cambios.value++;
  }

  static Future<void> _cargarMiniatura(Directory carpeta, Dibujo d) async {
    try {
      final png = File(_ruta(carpeta, d.id, 'png'));
      if (!await png.exists()) await _migrar(carpeta, d);
      if (!await png.exists()) return;
      final imagen =
          await _decodificar(await png.readAsBytes(), resolucionMiniatura);
      if (imagen != null) _ponerMiniatura(d.id, imagen);
    } catch (_) {
      // Un archivo dañado no debe impedir que se abra la app.
    }
  }

  /// Convierte lo pintado con la versión anterior (lista de manchas en un
  /// .json) a imagen .png. Si no hay nada que convertir, no hace nada.
  static Future<void> _migrar(Directory carpeta, Dibujo d) async {
    final viejo = File(_ruta(carpeta, d.id, 'json'));
    final versionInicial = version(d.id);
    try {
      if (!await viejo.exists()) return;
      final datos = jsonDecode(await viejo.readAsString());
      final trazos = <Trazo>[];
      if (datos is Map) {
        final regiones = datos['regiones'];
        if (regiones is Map) {
          for (var i = 0; i < d.regiones.length; i++) {
            final lista = regiones[d.regiones[i].id];
            if (lista is! List) continue;
            for (final t in lista) {
              final trazo = Trazo.desdeJson(t, i);
              if (trazo != null) trazos.add(trazo);
            }
          }
        }
      }
      if (trazos.isNotEmpty) {
        final dibujada = Dibujante.hornear(null, d, trazos, resolucion);
        final plana = await Dibujante.copiaPlana(dibujada, resolucion);
        dibujada.dispose();
        try {
          await _escribirPng(carpeta, d.id, plana, versionInicial);
        } finally {
          plana.dispose();
        }
      }
      await viejo.delete();
    } catch (_) {
      // Si no se pudo convertir, el .json queda para intentarlo otra vez.
    }
  }

  /// Prepara la imagen grande para pintar. Hay que llamar a [cerrar] después.
  static Future<void> abrir(Dibujo d) async {
    _abiertos[d.id] = (_abiertos[d.id] ?? 0) + 1;
    if (_completas.containsKey(d.id)) return;
    final versionInicial = version(d.id);
    await _cola; // por si se está guardando o borrando
    final carpeta = await _obtenerCarpeta();
    if (carpeta == null) return;
    final png = File(_ruta(carpeta, d.id, 'png'));
    try {
      if (!await png.exists()) await _migrar(carpeta, d);
      if (!await png.exists()) return;
      final imagen = await _decodificar(await png.readAsBytes(), resolucion);
      if (imagen == null) throw const FormatException('imagen vacía');
      if (_completas.containsKey(d.id) ||
          version(d.id) != versionInicial ||
          (_abiertos[d.id] ?? 0) == 0) {
        imagen.dispose();
        return;
      }
      _completas[d.id] = imagen;
    } catch (_) {
      // El archivo está dañado: se aparta (no se borra) y se empieza en blanco.
      try {
        await png.rename('${png.path}.danado');
      } catch (_) {}
    }
  }

  /// Agrega estas manchas terminadas a la imagen del dibujo.
  /// [versionLienzo] es la [version] que había al abrir el dibujo.
  static void hornear(Dibujo d, List<Trazo> trazos, int versionLienzo) {
    if (trazos.isEmpty || versionLienzo != version(d.id)) return;
    final base = _completas[d.id];
    final nueva = Dibujante.hornear(base, d, trazos, resolucion);
    _completas[d.id] = nueva;
    base?.dispose();
    _aplanar(d.id, nueva);
    _sucios.add(d.id);
    _temporizador?.cancel();
    _temporizador = Timer(const Duration(seconds: 2), () {
      guardarPendientes();
    });
  }

  /// En algunos celulares, una imagen recién horneada sigue "enlazada" a la
  /// anterior (y esa a la anterior...), lo que llenaría la memoria. Aquí se
  /// reemplaza por una copia plana, sin enlaces.
  static Future<void> _aplanar(String id, Image imagen) async {
    final copia = imagen.clone();
    try {
      final plana = await Dibujante.copiaPlana(copia, resolucion);
      if (identical(_completas[id], imagen)) {
        _completas[id] = plana;
        imagen.dispose();
        cambios.value++;
      } else {
        plana.dispose();
      }
    } catch (_) {
      // Si no se pudo, se queda la imagen como estaba.
    } finally {
      copia.dispose();
    }
  }

  /// Se terminó de usar el dibujo: actualiza su miniatura, lo guarda y
  /// libera la imagen grande.
  static Future<void> cerrar(Dibujo d) async {
    final quedan = (_abiertos[d.id] ?? 1) - 1;
    if (quedan <= 0) {
      _abiertos.remove(d.id);
    } else {
      _abiertos[d.id] = quedan;
    }
    await guardarPendientes();
    if ((_abiertos[d.id] ?? 0) == 0) {
      _completas.remove(d.id)?.dispose();
    }
  }

  /// Guarda ya mismo lo que cambió (y actualiza sus miniaturas).
  static Future<void> guardarPendientes() {
    _temporizador?.cancel();
    _temporizador = null;
    if (_sucios.isEmpty) return _cola;
    final ids = _sucios.toList();
    _sucios.clear();
    final copias = <String, Image>{};
    final versiones = <String, int>{};
    for (final id in ids) {
      final imagen = _completas[id];
      if (imagen == null) continue;
      copias[id] = imagen.clone();
      versiones[id] = version(id);
    }
    return _enCola((carpeta) async {
      for (final entrada in copias.entries) {
        final id = entrada.key;
        final imagen = entrada.value;
        try {
          final esperada = versiones[id] ?? -1;
          if (esperada != version(id)) continue; // se borró mientras tanto
          // Primero se guarda el archivo (lo más importante)...
          if (carpeta != null) await _escribirPng(carpeta, id, imagen, esperada);
          // ...y después se actualiza la miniatura del menú.
          final mini = await Dibujante.copiaPlana(imagen, resolucionMiniatura);
          if (esperada == version(id)) {
            _ponerMiniatura(id, mini);
            cambios.value++;
          } else {
            mini.dispose();
          }
        } catch (_) {
          // Si no se pudo guardar, se sigue pintando igual.
        } finally {
          imagen.dispose();
        }
      }
    });
  }

  static void borrar(Dibujo dibujo) => borrarId(dibujo.id);

  /// Deja TODOS estos dibujos en blanco.
  static void borrarTodos(List<Dibujo> dibujos) {
    for (final d in dibujos) {
      borrarId(d.id);
    }
  }

  /// Deja el dibujo en blanco y borra lo guardado en el celular.
  static void borrarId(String id) {
    _versiones[id] = version(id) + 1;
    _completas.remove(id)?.dispose();
    _miniaturas.remove(id)?.dispose();
    _sucios.remove(id);
    cambios.value++;
    _enCola((carpeta) async {
      if (carpeta == null) return;
      for (final extension in const <String>['png', 'json']) {
        final archivo = File(_ruta(carpeta, id, extension));
        if (await archivo.exists()) await archivo.delete();
      }
    });
  }

  static void _ponerMiniatura(String id, Image imagen) {
    final vieja = _miniaturas[id];
    _miniaturas[id] = imagen;
    vieja?.dispose();
  }

  static Future<Image?> _decodificar(Uint8List bytes, int lado) async {
    final codec = await instantiateImageCodec(
      bytes,
      targetWidth: lado,
      targetHeight: lado,
    );
    try {
      final cuadro = await codec.getNextFrame();
      return cuadro.image;
    } finally {
      codec.dispose();
    }
  }

  /// Escribe la imagen como PNG. Si mientras tanto se borró lo pintado
  /// (cambió la versión), no la escribe.
  static Future<void> _escribirPng(
    Directory carpeta,
    String id,
    Image imagen,
    int versionEsperada,
  ) async {
    final datos = await imagen
        .toByteData(format: ImageByteFormat.png)
        .timeout(const Duration(seconds: 15));
    if (datos == null) return;
    final ruta = _ruta(carpeta, id, 'png');
    final temporal = File('$ruta.tmp');
    await temporal.writeAsBytes(
      datos.buffer.asUint8List(datos.offsetInBytes, datos.lengthInBytes),
      flush: true,
    );
    if (version(id) != versionEsperada) {
      await temporal.delete();
      return;
    }
    await temporal.rename(ruta);
  }

  static Future<void> _enCola(Future<void> Function(Directory?) tarea) {
    _cola = _cola.then((_) async {
      try {
        // Nunca más de 30 segundos: la cola no se puede quedar trabada.
        await tarea(await _obtenerCarpeta()).timeout(const Duration(seconds: 30));
      } catch (_) {
        // Si algo falla al guardar o borrar, la app sigue funcionando.
      }
    });
    return _cola;
  }

  static Future<Directory?> _obtenerCarpeta() async {
    final carpeta = await (_carpeta ??= () async {
      try {
        final base = await getApplicationSupportDirectory();
        final carpeta = Directory('${base.path}${Platform.pathSeparator}pintura');
        await carpeta.create(recursive: true);
        return carpeta;
      } catch (_) {
        return null;
      }
    }());
    if (carpeta == null) _carpeta = null; // se reintenta la próxima vez
    return carpeta;
  }

  static String _ruta(Directory carpeta, String id, String extension) {
    final limpio = id.replaceAll(RegExp(r'[^A-Za-z0-9_\-]'), '_');
    return '${carpeta.path}${Platform.pathSeparator}$limpio.$extension';
  }
}
