import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../config.dart';
import '../servicios/sonidos.dart';
import '../servicios/voz.dart';
import 'pantalla_inicio.dart';

/// Presentación corta al abrir la app (unos 3,5 segundos): estrellas de
/// colores que caen, las letras de "PINTEMOS ARLETH" que aparecen saltando,
/// una musiquita y la voz que dice "¡Pintemos, Arleth!".
/// Tocar la pantalla la salta.
class PantallaPresentacion extends StatefulWidget {
  const PantallaPresentacion({super.key});

  @override
  State<PantallaPresentacion> createState() => _EstadoPresentacion();
}

class _EstadoPresentacion extends State<PantallaPresentacion>
    with SingleTickerProviderStateMixin {
  static const int _duracionMs = 3600;

  late final AnimationController _animacion = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: _duracionMs),
  );
  late final List<_Estrella> _estrellas = _Estrella.lluvia(36);
  bool _salio = false;

  @override
  void initState() {
    super.initState();
    _animacion.addStatusListener((estado) {
      if (estado == AnimationStatus.completed) _salir();
    });
    _animacion.forward();
    Voz.preparar();
    Sonidos.musicaPresentacion();
    Future<void>.delayed(const Duration(milliseconds: 700), () {
      if (!mounted || _salio) return;
      Voz.decir(Ajustes.presentacionVoz, tono: Ajustes.presentacionTono);
    });
  }

  @override
  void dispose() {
    _animacion.dispose();
    super.dispose();
  }

  void _salir() {
    if (_salio || !mounted) return;
    _salio = true;
    if (_animacion.isAnimating) {
      // La saltaron con un toque: se corta la música y la voz.
      Sonidos.pararMusica();
      Voz.parar();
    }
    Navigator.of(context).pushReplacement(
      PageRouteBuilder<void>(
        transitionDuration: const Duration(milliseconds: 600),
        pageBuilder: (context, animacion, secundaria) => const PantallaInicio(),
        transitionsBuilder: (context, animacion, secundaria, hijo) =>
            FadeTransition(opacity: animacion, child: hijo),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _salir,
        child: AnimatedBuilder(
          animation: _animacion,
          builder: (context, _) {
            final segundos = _animacion.value * _duracionMs / 1000.0;
            return Stack(
              fit: StackFit.expand,
              children: [
                const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: <Color>[
                        Color(0xFF81D4FA),
                        Color(0xFFF8BBD0),
                        Color(0xFFFFF4D6),
                      ],
                    ),
                  ),
                ),
                CustomPaint(painter: _PintorEstrellas(_estrellas, segundos)),
                SafeArea(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _Palabra(
                            texto: Ajustes.presentacionLinea1,
                            segundos: segundos,
                            inicio: 0.25,
                            tamano: 64,
                          ),
                          const SizedBox(height: 6),
                          _Palabra(
                            texto: Ajustes.presentacionLinea2,
                            segundos: segundos,
                            inicio: 1.0,
                            tamano: 86,
                          ),
                          const SizedBox(height: 36),
                          _GotasSaltarinas(segundos: segundos),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

const List<Color> _coloresAlegres = <Color>[
  Color(0xFFE53935),
  Color(0xFFFB8C00),
  Color(0xFFFDD835),
  Color(0xFF7CB342),
  Color(0xFF1E88E5),
  Color(0xFF8E24AA),
  Color(0xFFEC407A),
];

/// Una palabra cuyas letras aparecen una por una, saltando y girando.
class _Palabra extends StatelessWidget {
  const _Palabra({
    required this.texto,
    required this.segundos,
    required this.inicio,
    required this.tamano,
  });

  final String texto;
  final double segundos;
  final double inicio;
  final double tamano;

  @override
  Widget build(BuildContext context) {
    final letras = <Widget>[];
    for (var k = 0; k < texto.length; k++) {
      final avance =
          ((segundos - inicio - k * 0.09) / 0.55).clamp(0.0, 1.0).toDouble();
      final escala = math.max(0.01, Curves.elasticOut.transform(avance));
      final giro = (1 - avance) * 0.7 * (k.isEven ? 1 : -1);
      letras.add(
        Opacity(
          opacity: avance > 0 ? 1.0 : 0.0,
          child: Transform.rotate(
            angle: giro,
            child: Transform.scale(
              scale: escala,
              child: _Letra(
                letra: texto[k],
                color: _coloresAlegres[(k + texto.length) % _coloresAlegres.length],
                tamano: tamano,
              ),
            ),
          ),
        ),
      );
    }
    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Row(mainAxisSize: MainAxisSize.min, children: letras),
    );
  }
}

/// Una letra gordita de color con borde blanco.
class _Letra extends StatelessWidget {
  const _Letra({required this.letra, required this.color, required this.tamano});

  final String letra;
  final Color color;
  final double tamano;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Text(
          letra,
          style: TextStyle(
            fontSize: tamano,
            fontWeight: FontWeight.w900,
            foreground: Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = tamano * 0.16
              ..strokeJoin = StrokeJoin.round
              ..color = Colors.white,
            shadows: const <Shadow>[
              Shadow(color: Color(0x55000000), offset: Offset(0, 5), blurRadius: 8),
            ],
          ),
        ),
        Text(
          letra,
          style: TextStyle(
            fontSize: tamano,
            fontWeight: FontWeight.w900,
            color: color,
          ),
        ),
      ],
    );
  }
}

/// Gotas de pintura de colores que saltan como una ola.
class _GotasSaltarinas extends StatelessWidget {
  const _GotasSaltarinas({required this.segundos});

  final double segundos;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < 5; i++)
          Builder(builder: (context) {
            final avance =
                ((segundos - 1.7 - i * 0.08) / 0.5).clamp(0.0, 1.0).toDouble();
            final escala = math.max(0.01, Curves.elasticOut.transform(avance));
            final salto = -16 * math.max(0.0, math.sin(segundos * 7 - i * 0.7));
            return Opacity(
              opacity: avance > 0 ? 1.0 : 0.0,
              child: Transform.translate(
                offset: Offset(0, avance >= 1 ? salto : 0),
                child: Transform.scale(
                  scale: escala,
                  child: Container(
                    width: 30,
                    height: 30,
                    margin: const EdgeInsets.symmetric(horizontal: 7),
                    decoration: BoxDecoration(
                      color: _coloresAlegres[i + 1],
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 3),
                      boxShadow: const <BoxShadow>[
                        BoxShadow(color: Color(0x40000000), blurRadius: 4, offset: Offset(0, 3)),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }),
      ],
    );
  }
}

class _Estrella {
  _Estrella(this.x, this.velocidad, this.desfase, this.tamano, this.color, this.giro);

  final double x; // 0..1 del ancho
  final double velocidad; // alturas de pantalla por segundo
  final double desfase; // 0..1.35
  final double tamano; // radio en píxeles
  final Color color;
  final double giro; // vueltas por segundo

  static List<_Estrella> lluvia(int cantidad) {
    final azar = math.Random();
    return List<_Estrella>.generate(cantidad, (_) {
      return _Estrella(
        azar.nextDouble(),
        0.18 + azar.nextDouble() * 0.32,
        azar.nextDouble() * 1.35,
        7 + azar.nextDouble() * 15,
        _coloresAlegres[azar.nextInt(_coloresAlegres.length)],
        (azar.nextDouble() - 0.5) * 1.2,
      );
    });
  }
}

class _PintorEstrellas extends CustomPainter {
  _PintorEstrellas(this.estrellas, this.segundos);

  final List<_Estrella> estrellas;
  final double segundos;

  @override
  void paint(Canvas canvas, Size size) {
    final relleno = Paint()..style = PaintingStyle.fill;
    final borde = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeJoin = StrokeJoin.round
      ..color = Colors.white;
    for (final e in estrellas) {
      final y = ((segundos * e.velocidad + e.desfase) % 1.35) - 0.15;
      final x = e.x + 0.03 * math.sin(segundos * 2 + e.desfase * 5);
      final centro = Offset(x * size.width, y * size.height);
      final estrella = _forma(centro, e.tamano, segundos * e.giro * 2 * math.pi);
      relleno.color = e.color;
      canvas.drawPath(estrella, relleno);
      canvas.drawPath(estrella, borde);
    }
  }

  static Path _forma(Offset c, double r, double angulo) {
    final forma = Path();
    for (var i = 0; i < 10; i++) {
      final radio = i.isEven ? r : r * 0.45;
      final a = angulo - math.pi / 2 + i * math.pi / 5;
      final p = Offset(c.dx + radio * math.cos(a), c.dy + radio * math.sin(a));
      if (i == 0) {
        forma.moveTo(p.dx, p.dy);
      } else {
        forma.lineTo(p.dx, p.dy);
      }
    }
    forma.close();
    return forma;
  }

  @override
  bool shouldRepaint(covariant _PintorEstrellas oldDelegate) => true;
}
