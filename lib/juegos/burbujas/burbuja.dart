import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import 'package:colorear_ninos/juegos/burbujas/niveles.dart';

/// Una burbuja que flota por la pantalla.
class Burbuja {
  Burbuja({
    required this.id,
    required this.tipo,
    required this.centro,
    required this.radio,
    required this.color,
    required this.velocidad,
    required this.rumbo,
    required this.fase,
    this.nace = -10,
    this.toques = 1,
    this.animal,
  }) : toquesTotales = toques;

  /// Número único (para reconocerla).
  final int id;

  final TipoBurbuja tipo;

  /// Dónde está (en píxeles, dentro de la zona de juego).
  Offset centro;

  /// Su tamaño (la mitad de lo que mide de lado a lado).
  double radio;

  final Color color;

  /// Píxeles por segundo.
  double velocidad;

  /// Hacia dónde va (en radianes: 0 = derecha, pi/2 = abajo).
  double rumbo;

  /// Para que cada una tiemble y cambie de velocidad a su ritmo.
  final double fase;

  /// Cuándo apareció (segundos del juego), para que aparezca creciendo.
  final double nace;

  /// Cuántos toques le faltan para reventar.
  int toques;

  /// Cuántos toques necesitaba al salir.
  final int toquesTotales;

  /// El animalito de adentro (solo las de tipo animalito).
  final String? animal;

  /// Cuánto está girando ahora y hacia dónde quiere girar (radianes por
  /// segundo), y cuándo cambia de idea (segundos del juego).
  double giro = 0;
  double giroBuscado = 0;
  double proximoCambio = 0;

  /// true cuando ya entró entera a la pantalla (desde ahí rebota en los
  /// bordes y no se va).
  bool adentro = false;

  /// De 1 a 0: el "boing" cuando la tocan y le faltan toques.
  double golpe = 0;

  bool get variosToques => toquesTotales > 1;

  /// Las chiquitas se pueden tocar con un poco más de ayuda alrededor.
  bool get chiquita => tipo == TipoBurbuja.rapida || tipo == TipoBurbuja.chica;
}

/// Una explosión de burbuja: un anillo que se agranda, gotitas, papelitos,
/// estrellitas y la palabra "¡POP!".
class Estallido {
  Estallido({
    required this.centro,
    required this.radio,
    required this.color,
    required this.inicio,
    this.grande = false,
    this.chico = false,
    this.arcoiris = false,
    this.conPalabra = true,
  });

  final Offset centro;
  final double radio;
  final Color color;

  /// Cuándo empezó (segundos del juego).
  final double inicio;

  /// true = la de una súper, mega o arcoíris (más gotitas y estrellas).
  final bool grande;

  /// true = solo un destello (un toque que todavía no la revienta).
  final bool chico;

  /// true = de todos los colores.
  final bool arcoiris;

  /// true = sale la palabra "¡POP!" (o "¡PUM!" si es grande).
  final bool conPalabra;

  double get duracion => grande ? 1.1 : (chico ? 0.4 : 0.75);

  bool terminado(double ahora) => ahora - inicio >= duracion;
}

/// Un animalito que sale de su burbuja y se va volando contento.
class AnimalLibre {
  AnimalLibre(this.animal, this.centro, this.radio, this.inicio);

  final String animal;
  final Offset centro;
  final double radio;
  final double inicio;

  static const double duracion = 1.8;

  bool terminado(double ahora) => ahora - inicio >= duracion;
}

// =============================================================================
//  Dibujos ya hechos (letras y emojis): se dibujan una sola vez y después se
//  reutilizan, para que el juego vaya fluido.
// =============================================================================

class _Dibujos {
  static final Map<String, ui.Image?> _imagenes = <String, ui.Image?>{};

  /// La palabra [texto] con borde blanco, de color [color] (64 px de alto).
  static ui.Image? palabra(String texto, Color color, TextStyle? letra) {
    final clave = 'p|$texto|${color.toARGB32()}|${letra?.fontFamily}';
    return _imagenes.putIfAbsent(clave, () {
      final pintores = <TextPainter>[
        for (final borde in <bool>[true, false])
          TextPainter(
            text: TextSpan(
              text: texto,
              style: TextStyle(
                fontFamily: letra?.fontFamily,
                fontFamilyFallback: letra?.fontFamilyFallback,
                fontSize: 64,
                fontWeight: FontWeight.w900,
                letterSpacing: 1,
                foreground: borde
                    ? (Paint()
                      ..style = PaintingStyle.stroke
                      ..strokeWidth = 10
                      ..strokeJoin = StrokeJoin.round
                      ..color = Colors.white)
                    : (Paint()..color = color),
              ),
            ),
            textDirection: TextDirection.ltr,
          )..layout(),
      ];
      return _foto(pintores, 8);
    });
  }

  /// Un emoji (96 px).
  static ui.Image? emoji(String emoji, TextStyle? letra) {
    final clave = 'e|$emoji|${letra?.fontFamily}';
    return _imagenes.putIfAbsent(clave, () {
      final pintor = TextPainter(
        text: TextSpan(
          text: emoji,
          style: TextStyle(
            fontFamily: letra?.fontFamily,
            fontFamilyFallback: letra?.fontFamilyFallback,
            fontSize: 96,
            height: 1.1,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      return _foto(<TextPainter>[pintor], 4);
    });
  }

  static ui.Image? _foto(List<TextPainter> pintores, double margen) {
    try {
      final w = pintores.first.width + margen * 2;
      final h = pintores.first.height + margen * 2;
      final grabadora = ui.PictureRecorder();
      final canvas = Canvas(grabadora);
      for (final p in pintores) {
        p.paint(canvas, Offset(margen, margen));
      }
      final foto = grabadora.endRecording();
      final imagen = foto.toImageSync(w.ceil(), h.ceil());
      foto.dispose();
      return imagen;
    } catch (_) {
      return null;
    }
  }
}

/// Dibuja [imagen] centrada en [c], con [alto] de alto y [opacidad].
void _dibujarImagen(
    Canvas canvas, ui.Image imagen, Offset c, double alto, double opacidad) {
  final ancho = alto * imagen.width / imagen.height;
  canvas.drawImageRect(
    imagen,
    Rect.fromLTWH(0, 0, imagen.width.toDouble(), imagen.height.toDouble()),
    Rect.fromCenter(center: c, width: ancho, height: alto),
    Paint()
      ..filterQuality = FilterQuality.medium
      ..color = Color.fromRGBO(255, 255, 255, opacidad.clamp(0.0, 1.0)),
  );
}

// =============================================================================
//  Cómo se dibuja una burbuja
// =============================================================================

const List<Color> _arcoiris = <Color>[
  Color(0xFFFF5252),
  Color(0xFFFFAB40),
  Color(0xFFFFEB3B),
  Color(0xFF69F0AE),
  Color(0xFF40C4FF),
  Color(0xFFE040FB),
  Color(0xFFFF5252),
];

/// Dibuja la burbuja [b] en su lugar. [ahora] = segundos del juego (para
/// que tiemble como gelatina y brille). [letra] = la letra de la app
/// (para los emojis).
void pintarBurbuja(Canvas canvas, Burbuja b, double ahora, {TextStyle? letra}) {
  final r = b.radio;
  final color = b.color;

  // Aparece creciendo (con un saltito).
  final edad = ahora - b.nace;
  final crece = edad >= 0.3
      ? 1.0
      : Curves.easeOutBack.transform((edad / 0.3).clamp(0.0, 1.0));
  if (crece <= 0.01) return;

  // Tiembla suavecito (y mucho más cuando la tocan sin reventarla).
  final temblor = math.sin(ahora * 5 + b.fase) * 0.035;
  final boing = b.golpe * math.sin(b.golpe * math.pi * 4) * 0.22;
  final ex = (1 + temblor + boing) * crece;
  final ey = (1 - temblor - boing) * crece;

  // Las rápidas dejan una estela.
  if (b.tipo == TipoBurbuja.rapida) {
    final atras = Offset(-math.cos(b.rumbo), -math.sin(b.rumbo));
    for (var k = 3; k >= 1; k--) {
      canvas.drawCircle(
        b.centro + atras * (r * 0.85 * k),
        r * (1 - 0.2 * k),
        Paint()..color = color.withValues(alpha: 0.28 / k),
      );
    }
  }

  canvas.save();
  canvas.translate(b.centro.dx, b.centro.dy);
  canvas.scale(ex, ey);

  switch (b.tipo) {
    case TipoBurbuja.superBurbuja:
      _resplandor(canvas, r, const Color(0xFFFFD54F), ahora, b.fase);
    case TipoBurbuja.arcoiris:
      _resplandor(canvas, r, _arcoiris[(ahora * 3).floor() % 6], ahora, b.fase);
    case TipoBurbuja.rapida:
      _resplandor(canvas, r, Colors.white, ahora, b.fase);
    default:
      break;
  }

  _cuerpo(canvas, b, r, color, ahora);

  switch (b.tipo) {
    case TipoBurbuja.superBurbuja:
      final latido = 1 + 0.08 * math.sin(ahora * 6 + b.fase);
      _estrellaDorada(canvas, Offset(0, -r * 0.05), r * 0.36 * latido);
      _puntitos(canvas, r, b.toques, r * 0.55, const Color(0xFFFF8F00));
    case TipoBurbuja.mega:
      // Burbujitas que dan vueltas adentro.
      for (var i = 0; i < 4; i++) {
        final a = ahora * 0.8 + b.fase + i * math.pi / 2;
        final p = Offset(math.cos(a), math.sin(a)) * r * 0.42;
        final rr = r * 0.2;
        canvas.drawCircle(
            p, rr, Paint()..color = _arcoiris[i + 1].withValues(alpha: 0.45));
        canvas.drawCircle(
          p,
          rr,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = r * 0.025
            ..color = Colors.white.withValues(alpha: 0.9),
        );
        canvas.drawCircle(p + Offset(-rr * 0.35, -rr * 0.35), rr * 0.25,
            Paint()..color = Colors.white);
      }
      _puntitos(canvas, r, b.toques, r * 0.78, const Color(0xFF7B1FA2));
    case TipoBurbuja.animalito:
      final animal = b.animal;
      if (animal != null) {
        final imagen = _Dibujos.emoji(animal, letra);
        if (imagen != null) {
          final salto = math.sin(ahora * 3 + b.fase) * r * 0.06;
          _dibujarImagen(
              canvas, imagen, Offset(0, salto + r * 0.05), r * 1.15, 1);
        }
      }
    case TipoBurbuja.arcoiris:
      // Chispitas que brillan alrededor.
      for (var i = 0; i < 5; i++) {
        final a = i * 2 * math.pi / 5 + ahora * 1.2;
        final brillo = 0.5 + 0.5 * math.sin(ahora * 7 + i * 1.7);
        canvas.drawPath(
          estrella(Offset(math.cos(a), math.sin(a)) * r * 1.12,
              r * (0.08 + 0.07 * brillo), r * (0.035 + 0.03 * brillo)),
          Paint()..color = _arcoiris[i],
        );
      }
    default:
      break;
  }
  canvas.restore();
}

/// Para que los colores de un degradado circular vayan girando.
Float64List _girar(double angulo) {
  final c = math.cos(angulo);
  final s = math.sin(angulo);
  return Float64List.fromList(<double>[
    c, s, 0, 0, //
    -s, c, 0, 0, //
    0, 0, 1, 0, //
    0, 0, 0, 1, //
  ]);
}

/// Un brillo suave alrededor (sin desenfoque, que es más lento).
void _resplandor(
    Canvas canvas, double r, Color color, double ahora, double fase) {
  final latido = 0.5 + 0.5 * math.sin(ahora * 4 + fase);
  final rr = r * (1.3 + 0.06 * latido);
  canvas.drawCircle(
    Offset.zero,
    rr,
    Paint()
      ..shader = ui.Gradient.radial(
        Offset.zero,
        rr,
        <Color>[
          color.withValues(alpha: 0.0),
          color.withValues(alpha: 0.35 + 0.25 * latido),
          color.withValues(alpha: 0.0),
        ],
        <double>[0.6, 0.78, 1.0],
      ),
  );
}

/// El cuerpo transparente con borde de arcoíris y brillos.
void _cuerpo(Canvas canvas, Burbuja b, double r, Color color, double ahora) {
  final esArcoiris = b.tipo == TipoBurbuja.arcoiris;
  canvas.drawCircle(
    Offset.zero,
    r,
    Paint()
      ..shader = esArcoiris
          ? ui.Gradient.sweep(
              Offset.zero,
              <Color>[for (final c in _arcoiris) c.withValues(alpha: 0.5)],
              <double>[
                for (var i = 0; i < _arcoiris.length; i++)
                  i / (_arcoiris.length - 1),
              ],
              TileMode.clamp,
              0,
              2 * math.pi,
              _girar(ahora * 2),
            )
          : ui.Gradient.radial(
              Offset(-r * 0.25, -r * 0.3),
              r * 1.25,
              <Color>[
                Colors.white.withValues(alpha: 0.10),
                color.withValues(alpha: 0.12),
                color.withValues(alpha: 0.38),
                color.withValues(alpha: 0.70),
              ],
              <double>[0.0, 0.55, 0.85, 1.0],
            ),
  );

  // El borde de arcoíris (como el jabón).
  final grueso = switch (b.tipo) {
    TipoBurbuja.superBurbuja || TipoBurbuja.mega => 0.11,
    TipoBurbuja.rapida || TipoBurbuja.chica => 0.12,
    _ => 0.08,
  };
  canvas.drawCircle(
    Offset.zero,
    r * 0.96,
    Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = r * grueso
      ..shader = ui.Gradient.sweep(
        Offset.zero,
        <Color>[
          const Color(0xFFFF80AB).withValues(alpha: 0.65),
          const Color(0xFF80DEEA).withValues(alpha: 0.65),
          const Color(0xFFFFF59D).withValues(alpha: 0.75),
          const Color(0xFFB39DDB).withValues(alpha: 0.65),
          const Color(0xFFFF80AB).withValues(alpha: 0.65),
        ],
        <double>[0.0, 0.3, 0.5, 0.75, 1.0],
        TileMode.clamp,
        0,
        2 * math.pi,
        _girar(ahora * 0.6 + b.fase),
      ),
  );
  if (b.tipo == TipoBurbuja.superBurbuja) {
    canvas.drawCircle(
      Offset.zero,
      r,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = r * 0.05
        ..color = const Color(0xFFFFB300),
    );
  } else if (b.tipo == TipoBurbuja.mega) {
    canvas.drawCircle(
      Offset.zero,
      r,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = r * 0.035
        ..color = const Color(0xFFAB47BC),
    );
  }
  // Una línea finita para que se vea bien sobre el cielo claro.
  canvas.drawCircle(
    Offset.zero,
    r * 1.0,
    Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = r * 0.025
      ..color = Color.lerp(color, Colors.black, 0.25)!.withValues(alpha: 0.55),
  );

  // Los brillos blancos.
  canvas.save();
  canvas.translate(-r * 0.38, -r * 0.42);
  canvas.rotate(-0.65);
  canvas.drawOval(
    Rect.fromCenter(center: Offset.zero, width: r * 0.5, height: r * 0.26),
    Paint()..color = Colors.white.withValues(alpha: 0.9),
  );
  canvas.restore();
  canvas.drawCircle(Offset(-r * 0.08, -r * 0.66), r * 0.075,
      Paint()..color = Colors.white.withValues(alpha: 0.85));
  if (r > 25) {
    canvas.drawArc(
      Rect.fromCircle(center: Offset.zero, radius: r * 0.74),
      0.15,
      1.1,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = r * 0.07
        ..color = Colors.white.withValues(alpha: 0.5),
    );
  }
}

void _estrellaDorada(Canvas canvas, Offset c, double tam) {
  final camino = estrella(c, tam, tam * 0.45);
  canvas.drawPath(camino, Paint()..color = const Color(0xFFFFD54F));
  canvas.drawPath(
    camino,
    Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = tam * 0.08
      ..strokeJoin = StrokeJoin.round
      ..color = const Color(0xFFFF8F00),
  );
}

/// Puntitos blancos con los toques que le faltan.
void _puntitos(Canvas canvas, double r, int n, double y, Color borde) {
  final paso = r * 0.2;
  for (var i = 0; i < n; i++) {
    final p = Offset((i - (n - 1) / 2) * paso, y);
    canvas.drawCircle(p, r * 0.065, Paint()..color = Colors.white);
    canvas.drawCircle(
      p,
      r * 0.065,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = r * 0.02
        ..color = borde,
    );
  }
}

// =============================================================================
//  Las explosiones y los animalitos que se van volando
// =============================================================================

const List<Color> _brillos = <Color>[
  Color(0xFFFFEB3B),
  Color(0xFFFF4081),
  Color(0xFF40C4FF),
  Color(0xFF69F0AE),
  Color(0xFFE040FB),
  Color(0xFFFFAB40),
];

/// Dibuja las explosiones que están pasando.
void pintarEstallidos(Canvas canvas, List<Estallido> estallidos, double ahora,
    {TextStyle? letra}) {
  for (final e in estallidos) {
    if (ahora < e.inicio) continue; // todavía no empieza (fuegos en fila)
    final t = ((ahora - e.inicio) / e.duracion).clamp(0.0, 1.0);
    if (t >= 1) continue;
    final sale = Curves.easeOut.transform(t);
    final r = e.radio;
    final c = e.centro;
    final azar = math.Random(e.inicio.hashCode ^ c.dx.toInt());
    Color colorDe(int i) =>
        e.arcoiris ? _arcoiris[i % 6] : (i.isEven ? e.color : _brillos[i % 6]);

    // El anillo que se agranda.
    canvas.drawCircle(
      c,
      r * (e.chico ? 1.0 + 0.35 * sale : 0.9 + 0.7 * sale),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = r * 0.14 * (1 - t)
        ..color = (e.chico
                ? const Color(0xFFFFD54F)
                : (e.arcoiris ? _arcoiris[(t * 12).floor() % 6] : e.color))
            .withValues(alpha: 0.7 * (1 - t)),
    );
    if (e.chico) {
      // Solo unas chispitas alrededor.
      for (var i = 0; i < 6; i++) {
        final a = i * math.pi / 3 + azar.nextDouble() * 0.5;
        final p = c + Offset(math.cos(a), math.sin(a)) * r * (1.0 + 0.4 * sale);
        canvas.drawPath(
          estrella(p, r * 0.12 * (1 - t), r * 0.05 * (1 - t)),
          Paint()..color = _brillos[i % _brillos.length],
        );
      }
      continue;
    }

    // Un destello blanco al reventar.
    if (t < 0.2) {
      final f = t / 0.2;
      canvas.drawCircle(
        c,
        r * (0.8 + 0.5 * f),
        Paint()..color = Colors.white.withValues(alpha: 0.6 * (1 - f)),
      );
    }

    // Papelitos de colores que saltan, giran y caen.
    final papelitos = e.grande ? 18 : 9;
    for (var i = 0; i < papelitos; i++) {
      final a = 2 * math.pi * (i + 0.5) / papelitos + azar.nextDouble() * 0.5;
      final lejos = r * (0.6 + (1.0 + azar.nextDouble() * 1.2) * sale);
      final caida = r * 1.6 * t * t;
      final p = c + Offset(math.cos(a) * lejos, math.sin(a) * lejos + caida);
      canvas.save();
      canvas.translate(p.dx, p.dy);
      canvas.rotate(a + t * (6 + i % 4));
      canvas.drawRect(
        Rect.fromCenter(center: Offset.zero, width: r * 0.2, height: r * 0.1),
        Paint()
          ..color =
              colorDe(i + 1).withValues(alpha: (1 - t * t).clamp(0.0, 1.0)),
      );
      canvas.restore();
    }

    // Las gotitas que saltan (y caen un poquito).
    final gotas = e.grande ? 20 : 12;
    for (var i = 0; i < gotas; i++) {
      final a = 2 * math.pi * i / gotas + azar.nextDouble() * 0.4;
      final lejos = r * (0.5 + (1.2 + azar.nextDouble() * 0.8) * sale);
      final caida = r * 0.9 * t * t;
      final p = c + Offset(math.cos(a) * lejos, math.sin(a) * lejos + caida);
      final tamano = r * (0.08 + 0.09 * azar.nextDouble()) * (1 - t * 0.6);
      canvas.drawCircle(
          p, tamano, Paint()..color = colorDe(i).withValues(alpha: 1 - t));
      canvas.drawCircle(
        p + Offset(-tamano * 0.3, -tamano * 0.3),
        tamano * 0.35,
        Paint()..color = Colors.white.withValues(alpha: 0.8 * (1 - t)),
      );
    }

    // Estrellitas que giran.
    final estrellas = e.grande ? 9 : 5;
    for (var i = 0; i < estrellas; i++) {
      final a = 2 * math.pi * i / estrellas + 0.3;
      final lejos = r * (0.6 + (e.grande ? 2.0 : 1.4) * sale);
      final p = c + Offset(math.cos(a), math.sin(a)) * lejos;
      canvas.save();
      canvas.translate(p.dx, p.dy);
      canvas.rotate(t * math.pi * 2);
      final tamano = r * (e.grande ? 0.2 : 0.16) * (1 - t * 0.6);
      canvas.drawPath(
        estrella(Offset.zero, tamano, tamano * 0.45),
        Paint()..color = _brillos[i % _brillos.length].withValues(alpha: 1 - t),
      );
      canvas.restore();
    }

    // La palabra "¡POP!".
    if (e.conPalabra) {
      final crece = t < 0.25 ? Curves.easeOutBack.transform(t / 0.25) : 1.0;
      final opacidad = t < 0.6 ? 1.0 : (1 - (t - 0.6) / 0.4);
      final alto = r * (e.grande ? 0.95 : 0.7) * crece;
      final imagen = _Dibujos.palabra(e.grande ? '¡PUM!' : '¡POP!',
          _brillos[(e.inicio * 10).floor() % _brillos.length], letra);
      if (alto > 1 && imagen != null) {
        _dibujarImagen(
            canvas, imagen, c + Offset(0, -r * 0.35 * sale), alto, opacidad);
      }
    }
  }
}

/// Dibuja los animalitos que salieron de sus burbujas: suben moviéndose de
/// lado a lado, un poco más grandes, y se van apagando.
void pintarAnimales(Canvas canvas, List<AnimalLibre> animales, double ahora,
    {TextStyle? letra}) {
  for (final a in animales) {
    final t = ((ahora - a.inicio) / AnimalLibre.duracion).clamp(0.0, 1.0);
    if (t >= 1) continue;
    final imagen = _Dibujos.emoji(a.animal, letra);
    if (imagen == null) continue;
    final p = a.centro +
        Offset(math.sin(t * math.pi * 4) * a.radio * 0.5, -t * a.radio * 3.2);
    final tam = a.radio * 1.15 * (1 + 0.5 * Curves.easeOut.transform(t));
    final opacidad = t < 0.6 ? 1.0 : 1 - (t - 0.6) / 0.4;
    // Corazoncitos (estrellitas) alrededor.
    for (var i = 0; i < 3; i++) {
      final ang = t * 5 + i * 2.1;
      canvas.drawPath(
        estrella(p + Offset(math.cos(ang), math.sin(ang)) * tam * 0.7,
            tam * 0.1, tam * 0.045),
        Paint()..color = _brillos[i * 2].withValues(alpha: opacidad),
      );
    }
    canvas.save();
    canvas.translate(p.dx, p.dy);
    canvas.rotate(math.sin(t * math.pi * 6) * 0.2);
    _dibujarImagen(canvas, imagen, Offset.zero, tam, opacidad);
    canvas.restore();
  }
}

/// Una estrella de 5 puntas centrada en [c].
Path estrella(Offset c, double grande, double chica) {
  final camino = Path();
  for (var i = 0; i < 10; i++) {
    final a = -math.pi / 2 + i * math.pi / 5;
    final rr = i.isEven ? grande : chica;
    final p = c + Offset(math.cos(a), math.sin(a)) * rr;
    if (i == 0) {
      camino.moveTo(p.dx, p.dy);
    } else {
      camino.lineTo(p.dx, p.dy);
    }
  }
  return camino..close();
}

/// El dibujo de la tarjeta del menú: tres burbujas (se dibujan, no son un
/// emoji, para que se vean en todos los teléfonos).
class DibujoBurbujas extends StatelessWidget {
  const DibujoBurbujas({super.key});

  @override
  Widget build(BuildContext context) {
    return const AspectRatio(
      aspectRatio: 1,
      child: CustomPaint(painter: _PintorTarjeta()),
    );
  }
}

class _PintorTarjeta extends CustomPainter {
  const _PintorTarjeta();

  @override
  void paint(Canvas canvas, Size tam) {
    final l = tam.shortestSide;
    // (centro x, centro y, radio, color), en partes del lado.
    const burbujas = <(double, double, double, Color)>[
      (0.42, 0.56, 0.31, Color(0xFF29B6F6)),
      (0.78, 0.30, 0.17, Color(0xFFEC407A)),
      (0.80, 0.76, 0.12, Color(0xFFAB47BC)),
    ];
    for (final (x, y, r, color) in burbujas) {
      pintarBurbuja(
        canvas,
        Burbuja(
          id: 0,
          tipo: TipoBurbuja.normal,
          centro: Offset(x * l, y * l),
          radio: r * l,
          color: color,
          velocidad: 0,
          rumbo: 0,
          fase: x * 7,
        ),
        0,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _PintorTarjeta viejo) => false;
}
