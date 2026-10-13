import 'package:flutter/material.dart';

import '../config.dart';
import '../models/dibujo.dart';
import '../models/pintura.dart';
import '../models/tarritos.dart';
import '../servicios/sonidos.dart';
import '../servicios/voz.dart';
import '../widgets/botones.dart';
import '../widgets/lienzo.dart';
import '../widgets/paleta.dart';

/// Pantalla de pintar: arriba los botones grandes (inicio, anterior, siguiente,
/// borrar), en el medio el dibujo y abajo los colores.
class PantallaPintar extends StatefulWidget {
  const PantallaPintar({
    super.key,
    required this.dibujos,
    required this.indice,
  });

  final List<Dibujo> dibujos;
  final int indice;

  @override
  State<PantallaPintar> createState() => _EstadoPintar();
}

class _EstadoPintar extends State<PantallaPintar> {
  late int _indice;
  ColorConNombre _color = Ajustes.paleta.first;

  /// true mientras la voz dice el nombre del color (no se puede elegir otro).
  bool _hablando = false;

  /// Sube cada vez que se borra lo pintado (para empezar un lienzo nuevo).
  int _reinicios = 0;

  @override
  void initState() {
    super.initState();
    _indice = widget.indice;
    // La voz y los sonidos se preparan mientras tanto.
    Voz.preparar();
    Sonidos.preparar();
  }

  /// Para no repetir "¡Elige otro color!" a cada toque.
  DateTime _ultimoAviso = DateTime.fromMillisecondsSinceEpoch(0);

  Future<void> _elegirColor(ColorConNombre opcion) async {
    if (_hablando) return;
    setState(() => _color = opcion);
    await _hablar(opcion.nombre);
  }

  /// Dice una frase. Mientras habla, la paleta queda bloqueada para que la
  /// frase se escuche completa.
  Future<void> _hablar(String texto) async {
    if (_hablando) return;
    setState(() => _hablando = true);
    final inicio = DateTime.now();
    try {
      // Como mucho 5 segundos: la paleta nunca se queda bloqueada.
      await Voz.decir(texto).timeout(const Duration(seconds: 5));
    } catch (_) {
      // Si la voz falla o tarda, igual se sigue.
    }
    // Pausa mínima, aunque la voz termine antes (o no haya voz).
    final pasado = DateTime.now().difference(inicio);
    const minimo = Duration(milliseconds: Ajustes.pausaMinimaColor);
    if (pasado < minimo) {
      await Future<void>.delayed(minimo - pasado);
    }
    if (!mounted) return;
    setState(() => _hablando = false);
  }

  /// Avisos de los tarritos: se dicen SIN bloquear la paleta (así puede
  /// elegir otro color mientras escucha). Si [siempre] es false, no se
  /// repiten más de una vez cada 3 segundos.
  void _avisar(String texto, {bool siempre = false}) {
    final ahora = DateTime.now();
    if (!siempre) {
      if (_hablando || ahora.difference(_ultimoAviso) < const Duration(seconds: 3)) {
        return;
      }
    }
    _ultimoAviso = ahora;
    Voz.decir(texto);
  }

  String _conColor(String frase, ColorConNombre opcion) =>
      frase.replaceAll('{color}', opcion.nombre.toLowerCase());

  /// El lienzo pide pintura antes de cada mancha. Devuelve false si el
  /// tarrito del color elegido está vacío (entonces no se pinta).
  bool _gastarPintura() {
    final i = Ajustes.paleta.indexOf(_color);
    if (i < 0) return true;
    final tarritos = Tarritos.instancia;
    if (!tarritos.disponible(i)) {
      _pedirOtroColor();
      return false;
    }
    final seVacio = tarritos.usar(i);
    if (seVacio) _avisar(_conColor(Ajustes.vozSeAcabo, _color), siempre: true);
    return true;
  }

  void _pedirOtroColor() => _avisar(Ajustes.vozEligeOtro);

  void _tocoRellenando(ColorConNombre opcion) =>
      _avisar(_conColor(Ajustes.vozRellenando, opcion));

  Dibujo get _dibujo => widget.dibujos[_indice];

  void _mover(int paso) {
    final cantidad = widget.dibujos.length;
    setState(() {
      _indice = (_indice + paso + cantidad) % cantidad;
    });
  }

  Future<void> _reiniciar() async {
    final dibujo = _dibujo;
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (contexto) => AlertDialog(
        title: const Text('¿Borrar lo pintado y empezar de nuevo?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(contexto).pop(false),
            child: const Text('No'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(contexto).pop(true),
            child: const Text('Sí, borrar'),
          ),
        ],
      ),
    );
    if (!mounted) return;
    if (confirmado == true) {
      Pintura.borrar(dibujo);
      setState(() => _reinicios++);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Ajustes.fondoApp,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  BotonGrande(
                    icono: Icons.home_rounded,
                    color: const Color(0xFF1E88E5),
                    alTocar: () => Navigator.of(context).pop(),
                  ),
                  Row(
                    children: [
                      BotonGrande(
                        icono: Icons.arrow_back_rounded,
                        color: const Color(0xFFFB8C00),
                        alTocar: () => _mover(-1),
                      ),
                      const SizedBox(width: 14),
                      BotonGrande(
                        icono: Icons.arrow_forward_rounded,
                        color: const Color(0xFFFB8C00),
                        alTocar: () => _mover(1),
                      ),
                    ],
                  ),
                  BotonGrande(
                    icono: Icons.refresh_rounded,
                    color: const Color(0xFFE53935),
                    alTocar: _reiniciar,
                  ),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Lienzo(
                  key: ValueKey<String>('${_dibujo.id}#$_reinicios'),
                  dibujo: _dibujo,
                  color: _color.color,
                  alGastarPintura: _gastarPintura,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 16),
              child: ListenableBuilder(
                listenable: Tarritos.instancia,
                builder: (context, _) {
                  final tarritos = Tarritos.instancia;
                  return Paleta(
                    colores: Ajustes.paleta,
                    seleccionado: _color,
                    bloqueada: _hablando,
                    alElegir: _elegirColor,
                    alTocarRellenando: _tocoRellenando,
                    niveles: <double>[
                      for (var i = 0; i < Ajustes.paleta.length; i++)
                        tarritos.nivel(i),
                    ],
                    rellenando: <int>{
                      for (var i = 0; i < Ajustes.paleta.length; i++)
                        if (tarritos.rellenando(i)) i,
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
