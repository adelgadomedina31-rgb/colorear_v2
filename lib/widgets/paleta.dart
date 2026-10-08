import 'package:flutter/material.dart';

import '../config.dart';

/// Los colores para elegir: gotas de pintura brillantes sobre una bandeja
/// blanca, cinco por fila. La gota elegida se agranda, rebota y muestra una
/// estrellita.
///
/// Mientras la voz dice el nombre de un color, la paleta queda [bloqueada]:
/// los demás colores se ven más claros y no responden.
class Paleta extends StatelessWidget {
  const Paleta({
    super.key,
    required this.colores,
    required this.seleccionado,
    required this.alElegir,
    this.bloqueada = false,
  });

  final List<ColorConNombre> colores;
  final ColorConNombre seleccionado;
  final ValueChanged<ColorConNombre> alElegir;
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
          // Cinco gotas por fila, dejando lugar para que la elegida crezca.
          final tamano = ((restricciones.maxWidth - espacio * 4 - 2) / 5 / 1.12)
              .clamp(38.0, 68.0)
              .toDouble();
          return Wrap(
            alignment: WrapAlignment.center,
            spacing: espacio,
            runSpacing: espacio,
            children: [
              for (final opcion in colores)
                _Gota(
                  color: opcion.color,
                  tamano: tamano,
                  elegido: opcion.color == seleccionado.color,
                  apagado: bloqueada && opcion.color != seleccionado.color,
                  alTocar: bloqueada ? null : () => alElegir(opcion),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _Gota extends StatelessWidget {
  const _Gota({
    required this.color,
    required this.tamano,
    required this.elegido,
    required this.apagado,
    required this.alTocar,
  });

  final Color color;
  final double tamano;
  final bool elegido;
  final bool apagado;
  final VoidCallback? alTocar;

  Color _tono(double cambio) {
    final hsl = HSLColor.fromColor(color);
    return hsl
        .withLightness((hsl.lightness + cambio).clamp(0.0, 1.0).toDouble())
        .toColor();
  }

  @override
  Widget build(BuildContext context) {
    final claro = _tono(0.18);
    final oscuro = _tono(-0.16);
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: alTocar,
      child: SizedBox(
        width: tamano * 1.12,
        height: tamano * 1.12,
        child: Center(
          child: AnimatedOpacity(
            opacity: apagado ? 0.35 : 1.0,
            duration: const Duration(milliseconds: 150),
            child: AnimatedScale(
              scale: elegido ? 1.12 : 0.9,
              duration: const Duration(milliseconds: 450),
              curve: Curves.elasticOut,
              child: Container(
                width: tamano,
                height: tamano,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    center: const Alignment(-0.35, -0.4),
                    radius: 0.95,
                    colors: <Color>[claro, color, oscuro],
                    stops: const <double>[0.0, 0.55, 1.0],
                  ),
                  border: Border.all(
                    color: elegido ? Colors.white : oscuro,
                    width: elegido ? 4 : 2,
                  ),
                  boxShadow: <BoxShadow>[
                    if (elegido)
                      BoxShadow(color: oscuro, spreadRadius: 4, blurRadius: 0),
                    BoxShadow(
                      color: const Color(0x40000000),
                      blurRadius: elegido ? 10 : 4,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Stack(
                  children: [
                    // Brillo, para que parezca una gota de pintura.
                    Positioned(
                      left: tamano * 0.2,
                      top: tamano * 0.14,
                      child: Container(
                        width: tamano * 0.3,
                        height: tamano * 0.18,
                        decoration: BoxDecoration(
                          color: const Color(0x99FFFFFF),
                          borderRadius: BorderRadius.circular(tamano),
                        ),
                      ),
                    ),
                    if (elegido)
                      Center(
                        child: Icon(
                          Icons.star_rounded,
                          color: Colors.white,
                          size: tamano * 0.5,
                          shadows: const <Shadow>[
                            Shadow(color: Color(0x66000000), blurRadius: 4),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
