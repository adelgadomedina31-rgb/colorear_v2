import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../config.dart';
import '../models/dibujo.dart';
import '../models/pintura.dart';
import '../servicios/sonidos.dart';

/// Dibuja un dibujo junto con lo que se ha pintado. Se usa tanto en el
/// lienzo grande como en las miniaturas del menú.
class DibujoPainter extends CustomPainter {
  DibujoPainter({
    required this.dibujo,
    required this.pintura,
    this.derrames = const <Trazo, double>{},
  });

  final Dibujo dibujo;
  final List<List<Trazo>> pintura;

  /// Manchas que todavía se están "derramando" y cuánto les falta
  /// (0 = recién tocadas, 1 = terminadas).
  final Map<Trazo, double> derrames;

  @override
  void paint(Canvas canvas, Size size) {
    final escala = size.width / dibujo.lado;
    canvas.save();
    canvas.scale(escala, escala);

    final papel = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    final contorno = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.stroke
      ..strokeWidth = Ajustes.grosorContorno
      ..strokeJoin = StrokeJoin.round
      ..strokeCap = StrokeCap.round;
    final mancha = Paint()..style = PaintingStyle.fill;
    final franja = Paint()
      ..style = PaintingStyle.stroke
      ..strokeJoin = StrokeJoin.round
      ..strokeCap = StrokeCap.round;

    // Cada región: papel blanco, pintura recortada a su forma y contorno.
    // Las regiones de más abajo quedan tapadas por las de más arriba.
    for (var i = 0; i < dibujo.regiones.length; i++) {
      final region = dibujo.regiones[i];
      canvas.drawPath(region.path, papel);
      final trazos = i < pintura.length ? pintura[i] : const <Trazo>[];
      if (trazos.isNotEmpty) {
        canvas.save();
        canvas.clipPath(region.path);
        for (final trazo in trazos) {
          mancha.color = trazo.color;
          final avance = derrames[trazo];
          if (avance != null && avance < 1.0) {
            canvas.drawPath(
              Trazo.formaMancha(trazo.centro, trazo.radio, trazo.semilla, avance),
              mancha,
            );
          } else {
            canvas.drawPath(trazo.mancha, mancha);
          }
          final camino = trazo.franja;
          if (camino != null) {
            franja
              ..color = trazo.color
              ..strokeWidth = trazo.anchoFranja;
            canvas.drawPath(camino, franja);
          }
        }
        canvas.restore();
      }
      canvas.drawPath(region.path, contorno);
    }

    // Adornos encima de todo (ojos, sonrisas...).
    final detalleRelleno = Paint()..style = PaintingStyle.fill;
    final detalleLinea = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.stroke
      ..strokeJoin = StrokeJoin.round
      ..strokeCap = StrokeCap.round;
    for (final detalle in dibujo.detalles) {
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

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant DibujoPainter oldDelegate) => true;
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
class Lienzo extends StatefulWidget {
  const Lienzo({super.key, required this.dibujo, required this.color});

  final Dibujo dibujo;
  final Color color;

  @override
  State<Lienzo> createState() => _EstadoLienzo();
}

class _EstadoLienzo extends State<Lienzo> with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  final Stopwatch _reloj = Stopwatch()..start();
  final math.Random _azar = math.Random();

  /// Manchas que se están derramando y el momento (ms) en que nacieron.
  final Map<Trazo, int> _nacimientos = <Trazo, int>{};

  int? _puntero; // el dedo que está pintando (se ignoran los demás)
  int? _region; // índice de la región donde se está pintando
  Trazo? _trazo; // la mancha que se está pintando ahora
  double _recorrido = 0; // distancia arrastrada desde el último "plop"

  List<List<Trazo>> get _pintura => Pintura.de(widget.dibujo);

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_alTick);
    // Se calcula de una vez el tamaño de cada zona, justo después de mostrar
    // el dibujo, para que el primer toque no tenga que esperar.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      for (var i = 0; i < widget.dibujo.regiones.length; i++) {
        widget.dibujo.areaVisible(i);
      }
    });
  }

  @override
  void dispose() {
    _ticker.dispose();
    // Si quedó algo sin guardar (por ejemplo, al salir del dibujo), se guarda.
    Pintura.guardarPendientes();
    super.dispose();
  }

  void _alTick(Duration _) {
    final ahora = _reloj.elapsedMilliseconds;
    _nacimientos.removeWhere(
      (trazo, nacio) => ahora - nacio > Ajustes.duracionDerrame,
    );
    if (_nacimientos.isEmpty) _ticker.stop();
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
    final lista = _pintura[i];
    final Trazo trazo;
    if (area < Ajustes.areaUnToque) {
      // Zona pequeña: un círculo que la cubre entera.
      final caja = dibujo.regiones[i].path.getBounds();
      var radio = 0.0;
      for (final esquina in <Offset>[
        caja.topLeft,
        caja.topRight,
        caja.bottomLeft,
        caja.bottomRight,
      ]) {
        radio = math.max(radio, (esquina - p).distance);
      }
      // Lo de antes queda tapado por completo: no hace falta guardarlo.
      lista.clear();
      trazo = Trazo(color: widget.color, radio: radio + 4, semilla: 0, inicio: p);
    } else {
      trazo = Trazo(
        color: widget.color,
        radio: _radioPara(area),
        semilla: 1 + _azar.nextInt(1 << 30),
        inicio: p,
      );
    }
    lista.add(trazo);
    _region = i;
    _trazo = trazo;
    _recorrido = 0;
    _nacimientos[trazo] = _reloj.elapsedMilliseconds;
    if (!_ticker.isActive) _ticker.start();
    Sonidos.plop();
  }

  Offset _aDibujo(Offset local, double lado) =>
      local * (widget.dibujo.lado / lado);

  void _alBajar(PointerDownEvent e, double lado) {
    if (_puntero != null) return;
    _puntero = e.pointer;
    _region = null;
    _trazo = null;
    final p = _aDibujo(e.localPosition, lado);
    final i = _regionEn(p);
    if (i == null) return;
    setState(() => _empezar(p, i));
  }

  void _alMover(PointerMoveEvent e, double lado) {
    if (e.pointer != _puntero) return;
    final p = _aDibujo(e.localPosition, lado);
    final trazo = _trazo;
    if (_region == null || trazo == null) {
      // Empezó fuera del dibujo: se pega a la primera zona que toque.
      final i = _regionEn(p);
      if (i == null) return;
      setState(() => _empezar(p, i));
      return;
    }
    final anterior = trazo.puntos.last;
    if (trazo.sumar(p)) {
      _recorrido += (p - anterior).distance;
      if (_recorrido >= Ajustes.distanciaEntrePlops) {
        _recorrido = 0;
        Sonidos.plop(suave: true);
      }
      setState(() {});
    }
  }

  void _alSoltar(PointerEvent e) {
    if (e.pointer != _puntero) return;
    if (_trazo != null) Pintura.marcarCambio(widget.dibujo);
    _puntero = null;
    _region = null;
    _trazo = null;
  }

  Map<Trazo, double> _avances() {
    if (_nacimientos.isEmpty) return const <Trazo, double>{};
    final ahora = _reloj.elapsedMilliseconds;
    return _nacimientos.map(
      (trazo, nacio) => MapEntry(
        trazo,
        ((ahora - nacio) / Ajustes.duracionDerrame).clamp(0.0, 1.0).toDouble(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, restricciones) {
        final lado = math.min(restricciones.maxWidth, restricciones.maxHeight);
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
              child: CustomPaint(
                size: Size(lado, lado),
                painter: DibujoPainter(
                  dibujo: widget.dibujo,
                  pintura: _pintura,
                  derrames: _avances(),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
