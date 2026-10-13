import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../config.dart';

/// Los colores para elegir: tarritos redondos de pintura sobre una bandeja
/// blanca, cinco por fila. Cada tarrito muestra cuánta pintura le queda.
///
/// - La elegida se agranda, rebota y muestra una estrellita.
/// - Un tarrito que se está rellenando se ve más claro, con un relojito de
///   arena, y no se puede elegir (al tocarlo se llama a [alTocarRellenando]).
/// - Mientras la voz habla, la paleta queda [bloqueada].
class Paleta extends StatelessWidget {
  const Paleta({
    super.key,
    required this.colores,
    required this.seleccionado,
    required this.alElegir,
    required this.niveles,
    required this.rellenando,
    this.alTocarRellenando,
    this.bloqueada = false,
  });

  final List<ColorConNombre> colores;
  final ColorConNombre seleccionado;
  final ValueChanged<ColorConNombre> alElegir;

  /// Pintura que le queda a cada color (0 a 1), en el mismo orden.
  final List<double> niveles;

  /// Índices de los colores que se están rellenando.
  final Set<int> rellenando;

  final ValueChanged<ColorConNombre>? alTocarRellenando;
  final bool bloqueada;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 14, 10, 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: const Color(0xFFFFE0A3), width: 3),
        boxShadow: const [
          BoxShadow(
            color: Color(0x33000000),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, restricciones) {
          const espacio = 12.0;
          // Cinco tarritos por fila, dejando lugar para que el elegido crezca.
          final tamano = ((restricciones.maxWidth - espacio * 4 - 2) / 5 / 1.12)
              .clamp(38.0, 68.0)
              .toDouble();
          return Wrap(
            alignment: WrapAlignment.center,
            spacing: espacio,
            runSpacing: espacio,
            children: [
              for (var i = 0; i < colores.length; i++)
                _Tarrito(
                  color: colores[i].color,
                  tamano: tamano,
                  nivel: i < niveles.length ? niveles[i] : 1.0,
                  elegido: colores[i].color == seleccionado.color,
                  rellenandose: rellenando.contains(i),
                  apagado:
                      bloqueada && colores[i].color != seleccionado.color,
                  alTocar: bloqueada
                      ? null
                      : rellenando.contains(i)
                          ? (alTocarRellenando == null
                              ? null
                              : () => alTocarRellenando!(colores[i]))
                          : () => alElegir(colores[i]),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _Tarrito extends StatelessWidget {
  const _Tarrito({
    required this.color,
    required this.tamano,
    required this.nivel,
    required this.elegido,
    required this.rellenandose,
    required this.apagado,
    required this.alTocar,
  });

  final Color color;
  final double tamano;
  final double nivel;
  final bool elegido;
  final bool rellenandose;
  final bool apagado;
  final VoidCallback? alTocar;

  @override
  Widget build(BuildContext context) {
    final double escala = rellenandose ? 0.82 : (elegido ? 1.12 : 0.92);
    final double opacidad = rellenandose ? 0.6 : (apagado ? 0.35 : 1.0);
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: alTocar,
      child: SizedBox(
        width: tamano * 1.12,
        height: tamano * 1.12,
        child: Center(
          child: AnimatedOpacity(
            opacity: opacidad,
            duration: const Duration(milliseconds: 200),
            child: AnimatedScale(
              scale: escala,
              duration: const Duration(milliseconds: 450),
              curve: Curves.elasticOut,
              child: SizedBox(
                width: tamano,
                height: tamano,
                child: TweenAnimationBuilder<double>(
                  tween: Tween<double>(end: nivel),
                  duration: const Duration(milliseconds: 350),
                  curve: Curves.easeOut,
                  builder: (context, nivelAnimado, _) => CustomPaint(
                    painter: _PintorTarrito(
                      color: color,
                      nivel: nivelAnimado,
                      elegido: elegido,
                    ),
                    child: Center(
                      child: rellenandose
                          ? Icon(
                              Icons.hourglass_bottom_rounded,
                              color: Colors.white,
                              size: tamano * 0.5,
                              shadows: const <Shadow>[
                                Shadow(color: Color(0x99000000), blurRadius: 4),
                              ],
                            )
                          : elegido
                              ? Icon(
                                  Icons.star_rounded,
                                  color: Colors.white,
                                  size: tamano * 0.5,
                                  shadows: const <Shadow>[
                                    Shadow(color: Color(0x66000000), blurRadius: 4),
                                  ],
                                )
                              : null,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Dibuja un tarrito redondo: vidrio clarito, la pintura adentro hasta el
/// [nivel] (con la superficie ondulada) y un brillo.
class _PintorTarrito extends CustomPainter {
  _PintorTarrito({
    required this.color,
    required this.nivel,
    required this.elegido,
  });

  final Color color;
  final double nivel;
  final bool elegido;

  Color _tono(double cambio) {
    final hsl = HSLColor.fromColor(color);
    return hsl
        .withLightness((hsl.lightness + cambio).clamp(0.0, 1.0).toDouble())
        .toColor();
  }

  @override
  void paint(Canvas canvas, Size size) {
    final centro = size.center(Offset.zero);
    final radio = size.width / 2;
    final circulo = Rect.fromCircle(center: centro, radius: radio);
    final oscuro = _tono(-0.16);

    // Anillo de color cuando está elegido.
    if (elegido) {
      canvas.drawCircle(centro, radio + 4, Paint()..color = oscuro);
    }
    // Sombra.
    canvas.drawCircle(
      centro.translate(0, 3),
      radio,
      Paint()
        ..color = const Color(0x33000000)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
    );
    // Vidrio (tarrito vacío).
    canvas.drawCircle(centro, radio, Paint()..color = _tono(0.38));

    // Pintura adentro, hasta el nivel.
    final n = nivel.clamp(0.0, 1.0).toDouble();
    if (n > 0.001) {
      canvas.save();
      canvas.clipPath(Path()..addOval(circulo));
      final superficie = circulo.bottom - circulo.height * n;
      final ola = radio * 0.08 * (n < 0.98 ? 1.0 : 0.0);
      final liquido = Path()..moveTo(circulo.left, superficie);
      const pasos = 16;
      for (var k = 0; k <= pasos; k++) {
        final x = circulo.left + circulo.width * k / pasos;
        final y = superficie + ola * math.sin(k / pasos * 2 * math.pi * 1.5);
        liquido.lineTo(x, y);
      }
      liquido
        ..lineTo(circulo.right, circulo.bottom)
        ..lineTo(circulo.left, circulo.bottom)
        ..close();
      canvas.drawPath(
        liquido,
        Paint()
          ..shader = RadialGradient(
            center: const Alignment(-0.35, -0.4),
            radius: 0.95,
            colors: <Color>[_tono(0.18), color, oscuro],
            stops: const <double>[0.0, 0.55, 1.0],
          ).createShader(circulo),
      );
      canvas.restore();
    }

    // Borde.
    canvas.drawCircle(
      centro,
      radio - (elegido ? 2 : 1),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = elegido ? 4 : 2
        ..color = elegido ? Colors.white : oscuro,
    );
    // Brillo, para que parezca de vidrio.
    final brillo = Rect.fromLTWH(
      centro.dx - radio * 0.6,
      centro.dy - radio * 0.72,
      radio * 0.6,
      radio * 0.36,
    );
    canvas.drawOval(brillo, Paint()..color = const Color(0x99FFFFFF));
  }

  @override
  bool shouldRepaint(covariant _PintorTarrito oldDelegate) =>
      oldDelegate.color != color ||
      oldDelegate.nivel != nivel ||
      oldDelegate.elegido != elegido;
}
