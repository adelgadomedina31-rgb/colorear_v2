import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../config.dart';
import '../models/dibujo.dart';
import '../models/pintura.dart';
import '../servicios/sonidos.dart';

final Paint _suave = Paint()..filterQuality = FilterQuality.medium;

void _dibujarImagen(Canvas canvas, ui.Image imagen, Rect destino) {
  canvas.drawImageRect(
    imagen,
    Rect.fromLTWH(0, 0, imagen.width.toDouble(), imagen.height.toDouble()),
    destino,
    _suave,
  );
}

/// Miniatura de un dibujo para el menú: papel blanco, lo pintado y las líneas.
/// Se redibuja sola cuando cambia lo pintado ([Pintura.cambios]).
class MiniaturaPainter extends CustomPainter {
  MiniaturaPainter(this.dibujo) : super(repaint: Pintura.cambios);

  final Dibujo dibujo;

  @override
  void paint(Canvas canvas, Size size) {
    final todo = Offset.zero & size;
    canvas.drawRect(todo, Paint()..color = Colors.white);
    final pintado = Pintura.miniatura(dibujo.id);
    if (pintado != null) _dibujarImagen(canvas, pintado, todo);
    final lineas = Pintura.lineasMiniatura(dibujo);
    if (lineas != null) _dibujarImagen(canvas, lineas, todo);
  }

  @override
  bool shouldRepaint(covariant MiniaturaPainter oldDelegate) =>
      oldDelegate.dibujo != dibujo;
}

/// Una mancha que se está pintando ahora (todavía no horneada).
class _Activo {
  _Activo(this.trazo, this.nacio);

  final Trazo trazo;
  final int nacio; // milisegundos
}

class _PintorLienzo extends CustomPainter {
  _PintorLienzo({
    required this.dibujo,
    required this.activos,
    required this.avances,
    required this.lineas,
  }) : super(repaint: Pintura.cambios);

  final Dibujo dibujo;
  final List<Trazo> activos;
  final List<double> avances;
  final ui.Image? lineas;

  @override
  void paint(Canvas canvas, Size size) {
    final todo = Offset.zero & size;
    canvas.drawRect(todo, Paint()..color = Colors.white);
    // Se lee aquí (no antes) porque la imagen se reemplaza de vez en cuando.
    final base = Pintura.completa(dibujo.id);
    if (base != null) _dibujarImagen(canvas, base, todo);
    if (activos.isNotEmpty) {
      final escala = size.width / dibujo.lado;
      canvas.save();
      canvas.scale(escala, escala);
      for (var k = 0; k < activos.length; k++) {
        Dibujante.trazo(canvas, dibujo, activos[k], avances[k]);
      }
      canvas.restore();
    }
    final lineasActuales = lineas;
    if (lineasActuales != null) _dibujarImagen(canvas, lineasActuales, todo);
  }

  @override
  bool shouldRepaint(covariant _PintorLienzo oldDelegate) => true;
}

/// El lienzo donde se pinta con el dedo.
///
/// Cómo funciona:
///  - Cada toque deja una mancha de color que se "derrama" desde el dedo,
///    con un "plop". El tamaño de la mancha depende del tamaño de la zona:
///    las zonas grandes necesitan varios toques y las pequeñas se llenan de
///    un solo toque (ver Ajustes).
///  - Si el dedo se arrastra, la pintura lo sigue.
///  - La pintura queda "pegada" a la zona donde empezó el dedo y se recorta a
///    su forma, así que aunque el dedo se salga de las líneas el color no se sale.
///  - Cuando una mancha termina, se "hornea" dentro de la imagen del dibujo;
///    por eso pintar cuesta siempre lo mismo, aunque se pinte muchísimo.
class Lienzo extends StatefulWidget {
  const Lienzo({
    super.key,
    required this.dibujo,
    required this.color,
    this.alGastarPintura,
  });

  final Dibujo dibujo;
  final Color color;

  /// Se llama al empezar cada mancha (y cada tanto al arrastrar). Si
  /// devuelve false (el tarrito está vacío), no se pinta.
  final bool Function()? alGastarPintura;

  @override
  State<Lienzo> createState() => _EstadoLienzo();
}

class _EstadoLienzo extends State<Lienzo>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late final Ticker _ticker;
  late final int _version;
  final Stopwatch _reloj = Stopwatch()..start();
  final math.Random _azar = math.Random();
  final List<_Activo> _activos = <_Activo>[];

  bool _listo = false; // ya se cargó lo pintado antes
  ui.Image? _lineas;
  int _pxLineas = 0;

  int? _puntero; // el dedo que está pintando (se ignoran los demás)
  Trazo? _trazo; // la mancha que se está pintando ahora
  double _recorrido = 0; // distancia arrastrada desde el último "plop"
  bool _detenido = false; // se acabó la pintura a mitad de un arrastre

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_alTick);
    _version = Pintura.version(widget.dibujo.id);
    WidgetsBinding.instance.addObserver(this);
    _abrir();
    // Se calcula de una vez el tamaño de cada zona, justo después de mostrar
    // el dibujo, para que el primer toque no tenga que esperar.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // (Los dibujos hechos desde imagen lo calculan al tocar cada zona.)
      if (!mounted || !widget.dibujo.capas) return;
      for (var i = 0; i < widget.dibujo.regiones.length; i++) {
        widget.dibujo.areaVisible(i);
      }
    });
  }

  Future<void> _abrir() async {
    await Pintura.abrir(widget.dibujo);
    if (!mounted) return;
    setState(() => _listo = true);
  }

  /// Hornea ya mismo todo lo que se estaba pintando.
  void _hornearTodo() {
    final pendientes = _activos.map((a) => a.trazo).toList();
    _activos.clear();
    _trazo = null;
    _puntero = null;
    Pintura.hornear(widget.dibujo, pendientes, _version);
  }

  /// Si la app se va a segundo plano, se hornea y se guarda lo que haya.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // "inactive" (bajar la barra de notificaciones, un aviso del sistema)
    // no interrumpe la pintura; solo cuando la app se oculta de verdad.
    if (state == AppLifecycleState.resumed ||
        state == AppLifecycleState.inactive) {
      return;
    }
    if (_activos.isNotEmpty) {
      _hornearTodo();
      if (mounted) setState(() {});
    }
    Pintura.guardarPendientes();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _ticker.dispose();
    // Lo que se estaba pintando se guarda igual.
    _hornearTodo();
    Pintura.cerrar(widget.dibujo);
    _lineas?.dispose();
    _lineas = null;
    super.dispose();
  }

  void _alTick(Duration _) {
    final ahora = _reloj.elapsedMilliseconds;
    // Las manchas que ya terminaron de derramarse (y no se están arrastrando)
    // se hornean en la imagen, en orden.
    var listas = 0;
    while (listas < _activos.length) {
      final a = _activos[listas];
      final termino = ahora - a.nacio >= Ajustes.duracionDerrame &&
          !identical(a.trazo, _trazo);
      if (!termino) break;
      listas++;
    }
    if (listas > 0) {
      final horneadas = _activos.sublist(0, listas).map((a) => a.trazo).toList();
      _activos.removeRange(0, listas);
      Pintura.hornear(widget.dibujo, horneadas, _version);
    }
    if (_activos.isEmpty) _ticker.stop();
    setState(() {});
  }

  int? _regionEn(Offset p) {
    final regiones = widget.dibujo.regiones;
    for (var i = regiones.length - 1; i >= 0; i--) {
      if (regiones[i].path.contains(p)) return i;
    }
    return null;
  }

  /// Tamaño de la mancha para una zona con este área visible.
  double _radioPara(double area) {
    final t = ((math.log(area) - math.log(Ajustes.areaUnToque)) /
            (math.log(Ajustes.areaZonaGrande) - math.log(Ajustes.areaUnToque)))
        .clamp(0.0, 1.0);
    final toques = Ajustes.toquesZonaChica +
        (Ajustes.toquesZonaGrande - Ajustes.toquesZonaChica) * t;
    // El 2 compensa que los toques siempre se enciman un poco.
    final radio =
        math.sqrt(2 * area / (math.pi * toques)) * Ajustes.escalaMancha;
    return radio.clamp(Ajustes.radioMinimo, Ajustes.radioMaximo).toDouble();
  }

  void _empezar(Offset p, int i) {
    final dibujo = widget.dibujo;
    final area = dibujo.areaVisible(i);
    final Trazo trazo;
    if (area < Ajustes.areaUnToque) {
      // Zona pequeña: un círculo que la cubre entera.
      final caja = dibujo.limites(i);
      var radio = 0.0;
      for (final esquina in <Offset>[
        caja.topLeft,
        caja.topRight,
        caja.bottomLeft,
        caja.bottomRight,
      ]) {
        radio = math.max(radio, (esquina - p).distance);
      }
      trazo = Trazo(
        region: i,
        color: widget.color,
        radio: radio + 4,
        semilla: 0,
        inicio: p,
      );
    } else {
      trazo = Trazo(
        region: i,
        color: widget.color,
        radio: _radioPara(area),
        semilla: 1 + _azar.nextInt(1 << 30),
        inicio: p,
      );
    }
    _trazo = trazo;
    _recorrido = 0;
    _activos.add(_Activo(trazo, _reloj.elapsedMilliseconds));
    if (!_ticker.isActive) _ticker.start();
    Sonidos.plop();
  }

  Offset _aDibujo(Offset local, double lado) =>
      local * (widget.dibujo.lado / lado);

  bool _gastar() => widget.alGastarPintura?.call() ?? true;

  void _alBajar(PointerDownEvent e, double lado) {
    if (_puntero != null || !_listo) return;
    _puntero = e.pointer;
    _trazo = null;
    _detenido = false;
    final p = _aDibujo(e.localPosition, lado);
    final i = _regionEn(p);
    if (i == null) return;
    if (!_gastar()) {
      _detenido = true;
      return;
    }
    setState(() => _empezar(p, i));
  }

  void _alMover(PointerMoveEvent e, double lado) {
    if (e.pointer != _puntero || _detenido) return;
    final p = _aDibujo(e.localPosition, lado);
    final trazo = _trazo;
    if (trazo == null) {
      // Empezó fuera del dibujo: se pega a la primera zona que toque.
      final i = _regionEn(p);
      if (i == null) return;
      if (!_gastar()) {
        _detenido = true;
        return;
      }
      setState(() => _empezar(p, i));
      return;
    }
    final paso = (p - trazo.puntos.last).distance;
    if (paso < 6) return; // movimiento muy chiquito: se ignora
    if (_recorrido + paso >= Ajustes.distanciaEntrePlops) {
      // Arrastrar también gasta pintura.
      if (!_gastar()) {
        _detenido = true;
        _trazo = null;
        return;
      }
    }
    trazo.sumar(p);
    _recorrido += paso;
    if (_recorrido >= Ajustes.distanciaEntrePlops) {
      _recorrido = 0;
      Sonidos.plop();
    }
    setState(() {});
  }

  void _alSoltar(PointerEvent e) {
    if (e.pointer != _puntero) return;
    _puntero = null;
    _trazo = null;
    _detenido = false;
    // Para que la mancha se hornee aunque ya haya terminado de derramarse.
    if (_activos.isNotEmpty && !_ticker.isActive) _ticker.start();
  }

  void _asegurarLineas(int px) {
    if (_pxLineas == px) return;
    _pxLineas = px;
    if (widget.dibujo.lineasPng != null) {
      _leerLineasDeImagen(px); // dibujo hecho desde una imagen
      return;
    }
    _lineas?.dispose();
    _lineas = Dibujante.lineas(widget.dibujo, px);
  }

  Future<void> _leerLineasDeImagen(int px) async {
    final imagen = await Pintura.lineasDeImagen(widget.dibujo, px);
    if (imagen == null) {
      // No se pudo leer: se vuelven a hacer las líneas desde las zonas.
      if (mounted) setState(() => _pxLineas = 0);
      return;
    }
    if (!mounted || _pxLineas != px) {
      imagen.dispose();
      return;
    }
    final vieja = _lineas;
    setState(() => _lineas = imagen);
    vieja?.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final densidad = MediaQuery.devicePixelRatioOf(context);
    return LayoutBuilder(
      builder: (context, restricciones) {
        final lado = math.min(restricciones.maxWidth, restricciones.maxHeight);
        _asegurarLineas((lado * densidad).round().clamp(200, 2048).toInt());
        final ahora = _reloj.elapsedMilliseconds;
        final avances = <double>[
          for (final a in _activos)
            ((ahora - a.nacio) / Ajustes.duracionDerrame).clamp(0.0, 1.0).toDouble(),
        ];
        return Center(
          child: SizedBox(
            width: lado,
            height: lado,
            child: Listener(
              behavior: HitTestBehavior.opaque,
              onPointerDown: (e) => _alBajar(e, lado),
              onPointerMove: (e) => _alMover(e, lado),
              onPointerUp: _alSoltar,
              onPointerCancel: _alSoltar,
              child: RepaintBoundary(
                child: CustomPaint(
                  size: Size(lado, lado),
                  painter: _PintorLienzo(
                    dibujo: widget.dibujo,
                    activos: <Trazo>[for (final a in _activos) a.trazo],
                    avances: avances,
                    lineas: _lineas,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
