import 'package:flutter/foundation.dart' show ChangeNotifier;

import '../config.dart';

/// Los tarritos de pintura: uno por cada color de la paleta.
///
/// - Cada toque gasta un poco de pintura del color que se usa.
/// - Cuando un tarrito se vacía, queda "rellenándose": no se puede usar
///   hasta que esté lleno otra vez.
/// - Se rellena solo mientras se pinta con OTROS colores (así se aprende a
///   usar varios colores).
///
/// Los niveles se mantienen mientras la app está abierta (al cerrarla y
/// abrirla de nuevo, todos los tarritos empiezan llenos).
class Tarritos extends ChangeNotifier {
  Tarritos._();

  static final Tarritos instancia = Tarritos._();

  final List<double> _niveles =
      List<double>.filled(Ajustes.paleta.length, 1.0);
  final Set<int> _rellenando = <int>{};

  /// Cuánta pintura tiene el color [i]: de 0 (vacío) a 1 (lleno).
  double nivel(int i) => _niveles[i];

  /// true si el color [i] se está rellenando (no se puede usar).
  bool rellenando(int i) => _rellenando.contains(i);

  /// true si el color [i] se puede usar ahora.
  bool disponible(int i) => !_rellenando.contains(i) && _niveles[i] > 0.0001;

  /// Gasta un toque de pintura del color [i]. Devuelve true si con este
  /// toque el tarrito se vació.
  bool usar(int i) {
    if (!disponible(i)) return false;
    // Los tarritos vacíos se rellenan un poco cuando se usa otro color.
    final listos = <int>[];
    for (final j in _rellenando) {
      if (j == i) continue;
      final nuevo = _niveles[j] + 1 / Ajustes.toquesParaRellenar;
      _niveles[j] = nuevo > 1.0 ? 1.0 : nuevo;
      if (_niveles[j] >= 0.999) listos.add(j);
    }
    for (final j in listos) {
      _niveles[j] = 1.0;
      _rellenando.remove(j);
    }
    _niveles[i] = _niveles[i] - 1 / Ajustes.toquesPorTarrito;
    var seVacio = false;
    if (_niveles[i] <= 0.0001) {
      _niveles[i] = 0.0;
      _rellenando.add(i);
      seVacio = true;
      // Seguridad: nunca pueden quedar TODOS los colores rellenándose.
      if (_rellenando.length >= _niveles.length) {
        for (final j in _rellenando.where((j) => j != i).toList()) {
          _niveles[j] = 1.0;
          _rellenando.remove(j);
        }
      }
    }
    notifyListeners();
    return seVacio;
  }
}
