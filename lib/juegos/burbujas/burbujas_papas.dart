import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Recuerda en qué nivel va el juego de Burbujas (queda guardado en el
/// celular, aunque se cierre la app).
class ProgresoBurbujas {
  ProgresoBurbujas._();

  static const String _clave = 'burbujas_nivel';

  /// El nivel guardado (1 si nunca jugó).
  static Future<int> cargar() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final nivel = prefs.getInt(_clave) ?? 1;
      return nivel < 1 ? 1 : nivel;
    } catch (_) {
      return 1;
    }
  }

  static Future<void> guardar(int nivel) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_clave, nivel < 1 ? 1 : nivel);
    } catch (_) {
      // Si no se pudo guardar, la próxima vez empieza donde estaba antes.
    }
  }
}

/// La parte de Burbujas en la pantalla de Ajustes (engranaje, zona de
/// papás): en qué nivel va y un botón para volver al nivel 1.
class BurbujasPapas extends StatefulWidget {
  const BurbujasPapas({super.key});

  @override
  State<BurbujasPapas> createState() => _EstadoBurbujasPapas();
}

class _EstadoBurbujasPapas extends State<BurbujasPapas> {
  int? _nivel;

  @override
  void initState() {
    super.initState();
    ProgresoBurbujas.cargar().then((nivel) {
      if (mounted) setState(() => _nivel = nivel);
    });
  }

  Future<void> _volverAlUno() async {
    await ProgresoBurbujas.guardar(1);
    if (mounted) setState(() => _nivel = 1);
  }

  @override
  Widget build(BuildContext context) {
    final nivel = _nivel;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          nivel == null ? 'Nivel: ...' : 'Va en el nivel $nivel.',
          key: const ValueKey<String>('burbujas_nivel_papas'),
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        const Text(
          'El juego recuerda el nivel. Los niveles no se acaban: cada pocos '
          'niveles aparece un tipo de burbuja nuevo.',
        ),
        const SizedBox(height: 10),
        OutlinedButton.icon(
          key: const ValueKey<String>('burbujas_reiniciar'),
          onPressed: nivel == null || nivel == 1 ? null : _volverAlUno,
          icon: const Icon(Icons.restart_alt_rounded),
          label: const Text('Volver al nivel 1'),
        ),
      ],
    );
  }
}
