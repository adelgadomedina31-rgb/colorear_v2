import 'dart:async';

import 'package:flutter_tts/flutter_tts.dart';

import '../config.dart';

/// La voz que dice el nombre de los colores.
///
/// Usa el "texto a voz" del propio celular (funciona sin internet si el
/// celular tiene descargada la voz en español). Se busca una voz femenina en
/// español y se le sube el tono para que suene más infantil.
///
/// Para que nunca se trabe: cada paso tiene un tiempo máximo de espera, y el
/// fin de cada frase se detecta con los avisos del motor de voz (si el aviso
/// no llega, igual se sigue después de un momento).
class Voz {
  Voz._();

  static final FlutterTts _tts = FlutterTts();
  static Future<bool>? _preparada;
  static Completer<void>? _frase;
  static final Stopwatch _reloj = Stopwatch()..start();
  static int _inicioFrase = 0;

  /// Deja la voz lista. Se puede llamar varias veces; solo prepara una vez
  /// (si falla, se reintenta la próxima vez).
  static Future<bool> preparar() {
    final existente = _preparada;
    if (existente != null) return existente;
    final nueva = _configurar().timeout(
      const Duration(seconds: 5),
      onTimeout: () => false,
    );
    _preparada = nueva;
    nueva.then((bien) {
      if (!bien) _preparada = null;
    });
    return nueva;
  }

  static Future<bool> _configurar() async {
    try {
      // speak() no espera a que termine; el final llega por estos avisos.
      await _tts.awaitSpeakCompletion(false);
      _tts.setCompletionHandler(_terminoFrase);
      _tts.setCancelHandler(_terminoFrase);
      // Un error termina la frase enseguida (sin esperar).
      _tts.setErrorHandler((_) {
        final frase = _frase;
        if (frase != null && !frase.isCompleted) frase.complete();
      });

      // Primero español latino; si no hay, cualquier español.
      for (final idioma in const <String>['es-US', 'es-PE', 'es-MX', 'es-419', 'es-ES', 'es']) {
        final disponible = await _tts.isLanguageAvailable(idioma);
        if (disponible == true) {
          await _tts.setLanguage(idioma);
          break;
        }
      }
      await _elegirVozFemenina();
      await _tts.setPitch(Ajustes.vozTono);
      await _tts.setSpeechRate(Ajustes.vozVelocidad);
      await _tts.setVolume(1.0);
      return true;
    } catch (_) {
      return false;
    }
  }

  static void _terminoFrase() {
    // Un aviso que llega enseguida de empezar es de la frase anterior.
    if (_reloj.elapsedMilliseconds - _inicioFrase < 150) return;
    final frase = _frase;
    if (frase != null && !frase.isCompleted) frase.complete();
  }

  /// Si el celular dice cuál de sus voces en español es femenina, se usa esa.
  /// Si no lo dice, se deja la voz por defecto (en Android suele ser femenina).
  static Future<void> _elegirVozFemenina() async {
    try {
      final voces = await _tts.getVoices;
      if (voces is! List) return;
      Map<String, String>? mejor;
      var mejorPuntaje = 0;
      for (final v in voces) {
        if (v is! Map) continue;
        final nombre = '${v['name'] ?? ''}';
        final idioma = '${v['locale'] ?? ''}';
        final n = nombre.toLowerCase();
        final l = idioma.toLowerCase();
        final genero = '${v['gender'] ?? ''}'.toLowerCase();
        final extras = '${v['features'] ?? ''}'.toLowerCase();
        if (!l.startsWith('es')) continue;
        if (extras.contains('notinstalled')) continue;
        final esFemenina =
            genero == 'female' || n.contains('female') || n.contains('femenin');
        if (!esFemenina) continue;
        var puntaje = 10;
        if (n.contains('local')) puntaje += 3; // funciona sin internet
        if ('${v['network_required']}' == '1') puntaje -= 3;
        if (l.contains('us') || l.contains('419') || l.contains('mx')) {
          puntaje += 1;
        }
        if (puntaje > mejorPuntaje) {
          mejorPuntaje = puntaje;
          mejor = <String, String>{'name': nombre, 'locale': idioma};
        }
      }
      if (mejor != null) await _tts.setVoice(mejor);
    } catch (_) {
      // Si falla, se queda la voz por defecto.
    }
  }

  /// Dice [texto] y espera a que termine (como mucho unos 3 segundos).
  /// Nunca se queda esperando para siempre.
  static Future<void> decir(String texto) async {
    if (!Ajustes.vozActiva) return;
    final lista = await preparar();
    if (!lista) return;
    final anterior = _frase; // por si quedó una frase sin terminar
    if (anterior != null && !anterior.isCompleted) anterior.complete();
    final frase = Completer<void>();
    _frase = frase;
    _inicioFrase = _reloj.elapsedMilliseconds;
    try {
      await _tts.speak(texto).timeout(const Duration(seconds: 2));
      await frase.future.timeout(const Duration(milliseconds: 2500));
    } catch (_) {
      // Sin voz no pasa nada: la app sigue funcionando.
    } finally {
      if (identical(_frase, frase)) _frase = null;
    }
  }
}
