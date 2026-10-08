import 'package:flutter/material.dart';

import '../config.dart';
import '../models/dibujo.dart';
import '../models/pintura.dart';
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

  @override
  void initState() {
    super.initState();
    _indice = widget.indice;
    Voz.preparar(); // la voz se prepara mientras tanto
  }

  Future<void> _elegirColor(ColorConNombre opcion) async {
    if (_hablando) return;
    setState(() {
      _color = opcion;
      _hablando = true;
    });
    final inicio = DateTime.now();
    await Voz.decir(opcion.nombre);
    // Pausa mínima, aunque la voz termine antes (o no haya voz).
    final pasado = DateTime.now().difference(inicio);
    const minimo = Duration(milliseconds: Ajustes.pausaMinimaColor);
    if (pasado < minimo) {
      await Future<void>.delayed(minimo - pasado);
    }
    if (!mounted) return;
    setState(() => _hablando = false);
  }

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
      setState(() {});
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
                  key: ValueKey<String>(_dibujo.id),
                  dibujo: _dibujo,
                  color: _color.color,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 16),
              child: Paleta(
                colores: Ajustes.paleta,
                seleccionado: _color,
                bloqueada: _hablando,
                alElegir: _elegirColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
