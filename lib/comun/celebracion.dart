import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:colorear_ninos/app/ajustes_app.dart';

/// La celebración de todos los juegos: un cartel grande con dos líneas
/// (por ejemplo "¡FELICIDADES!" y "LO PINTASTE MUY BIEN"), estrellas que
/// giran y brillan alrededor, y estrellitas que salen volando como fuegos
/// artificiales.
///
/// Se quita sola después de [AjustesApp.segundosCelebracion] segundos (o los
/// [segundos] que diga el juego), o
/// tocándola. Mientras está, no se puede tocar el juego de atrás.
/// (El sonido de la fiesta lo pone cada juego con Sonidos.felicidades().)
class Celebracion extends StatefulWidget {
  const Celebracion({
    super.key,
    required this.linea1,
    required this.linea2,
    required this.alTerminar,
    this.segundos,
  });

  /// Lo que se ve en grande en el cartel: la primera línea (más grande) y
  /// la segunda.
  final String linea1;
  final String linea2;

  /// Se llama cuando la celebración terminó de irse.
  final VoidCallback alTerminar;

  /// (Opcional) Cuántos segundos se queda. Si no se dice, los de
  /// [AjustesApp.segundosCelebracion].
  final int? segundos;

  @override
  State<Celebracion> createState() => _EstadoCelebracion();
}

class _EstadoCelebracion extends State<Celebracion>
    with TickerProviderStateMixin {
  /// Aparece el cartel (con rebote).
  late final AnimationController _entrada = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..forward();

  /// Las estrellas giran y brillan todo el tiempo.
  late final AnimationController _giro = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 6),
  )..repeat();

  /// Se va (se desvanece).
  late final AnimationController _salida = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 350),
  );

  Timer? _reloj;
  bool _saliendo = false;

  static const List<Color> _coloresEstrellas = <Color>[
    Color(0xFFFDD835),
    Color(0xFFFB8C00),
    Color(0xFFEC407A),
    Color(0xFF1E88E5),
    Color(0xFF7CB342),
    Color(0xFF8E24AA),
    Color(0xFF00ACC1),
    Color(0xFFE53935),
  ];

  @override
  void initState() {
    super.initState();
    _reloj = Timer(
        Duration(seconds: widget.segundos ?? AjustesApp.segundosCelebracion),
        _cerrar);
  }

  @override
  void dispose() {
    _reloj?.cancel();
    _entrada.dispose();
    _giro.dispose();
    _salida.dispose();
    super.dispose();
  }

  Future<void> _cerrar() async {
    if (_saliendo) return;
    _saliendo = true;
    _reloj?.cancel();
    await _salida.forward();
    if (mounted) widget.alTerminar();
  }

  void _alTocar() {
    // Un toque apurado justo al aparecer no la quita.
    if (_entrada.value < 1.0) return;
    _cerrar();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      key: const ValueKey<String>('celebracion'),
      behavior: HitTestBehavior.opaque,
      onTap: _alTocar,
      child: AnimatedBuilder(
        animation: Listenable.merge(<Listenable>[_entrada, _giro, _salida]),
        builder: (context, _) {
          final opacidad = 1.0 - _salida.value;
          return Opacity(
            opacity: opacidad,
            child: LayoutBuilder(
              builder: (context, caja) => _contenido(caja.biggest),
            ),
          );
        },
      ),
    );
  }

  Widget _contenido(Size tam) {
    final aparecer = Curves.easeOut.transform(_entrada.value.clamp(0.0, 1.0));
    final rebote = Curves.elasticOut.transform(_entrada.value.clamp(0.0, 1.0));
    final t = _giro.value;
    final centro = Offset(tam.width / 2, tam.height / 2);
    final anchoCartel = math.min(tam.width * 0.76, 540.0);
    final altoCartel = anchoCartel * 0.48;
    final hijos = <Widget>[
      // Fondo oscurecido para que resalte el cartel.
      Positioned.fill(
        child: ColoredBox(color: Color.fromRGBO(0, 0, 0, 0.35 * aparecer)),
      ),
    ];

    // Fuegos artificiales: estrellitas que salen del centro hacia afuera.
    final lejos = math.max(tam.width, tam.height) * 0.6;
    for (var i = 0; i < 18; i++) {
      final fase = (t * 3 + i / 18) % 1.0;
      final angulo = i * 2.39996; // ángulo dorado: quedan bien repartidas
      final distancia = anchoCartel * 0.25 + fase * lejos;
      final tamEstrella = 16.0 + 14 * (i % 3);
      hijos.add(_estrella(
        centro + Offset(math.cos(angulo), math.sin(angulo)) * distancia,
        tamEstrella,
        _coloresEstrellas[i % _coloresEstrellas.length],
        (1 - fase) * aparecer,
        fase * math.pi,
      ));
    }

    // El cartel, que aparece rebotando.
    hijos.add(Positioned(
      left: centro.dx - anchoCartel / 2,
      top: centro.dy - altoCartel / 2,
      width: anchoCartel,
      height: altoCartel,
      child: Transform.scale(
        scale: 0.3 + 0.7 * rebote,
        child: _cartel(),
      ),
    ));

    // Estrellas grandes que giran alrededor del cartel y brillan.
    // (sin salirse de la pantalla).
    const cantidad = 12;
    final radioX = math.min(anchoCartel / 2 + 34, tam.width / 2 - 30);
    final radioY = math.min(altoCartel / 2 + 64, tam.height / 2 - 30);
    for (var i = 0; i < cantidad; i++) {
      final angulo = 2 * math.pi * (i / cantidad + t);
      final brillo = 0.5 + 0.5 * math.sin(2 * math.pi * (t * 4) + i * 1.3);
      final tamEstrella = (38.0 + 20 * brillo) * rebote.clamp(0.0, 1.2);
      hijos.add(_estrella(
        centro + Offset(math.cos(angulo) * radioX, math.sin(angulo) * radioY),
        tamEstrella,
        _coloresEstrellas[i % _coloresEstrellas.length],
        aparecer,
        angulo,
      ));
    }

    return Stack(clipBehavior: Clip.none, children: hijos);
  }

  Widget _estrella(
      Offset donde, double tam, Color color, double opacidad, double giro) {
    return Positioned(
      left: donde.dx - tam / 2,
      top: donde.dy - tam / 2,
      width: tam,
      height: tam,
      child: Opacity(
        opacity: opacidad.clamp(0.0, 1.0),
        child: Transform.rotate(
          angle: giro,
          child: Icon(
            Icons.star_rounded,
            size: tam,
            color: color,
            shadows: const <Shadow>[
              Shadow(color: Color(0x88FFFFFF), blurRadius: 6),
            ],
          ),
        ),
      ),
    );
  }

  Widget _cartel() {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(36),
        border: Border.all(color: const Color(0xFFFDD835), width: 7),
        boxShadow: const <BoxShadow>[
          BoxShadow(
              color: Color(0x55000000), blurRadius: 18, offset: Offset(0, 6)),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Expanded(
              flex: 5,
              child: FittedBox(
                fit: BoxFit.contain,
                child: Text(
                  widget.linea1,
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    color: Color(0xFFFB8C00),
                    fontSize: 64,
                    letterSpacing: 1.5,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 4),
            Expanded(
              flex: 3,
              child: FittedBox(
                fit: BoxFit.contain,
                child: Text(
                  widget.linea2,
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF8E24AA),
                    fontSize: 40,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
