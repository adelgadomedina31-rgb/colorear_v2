import 'package:flutter_tts/flutter_tts.dart';

import '../config.dart';

/// La voz que dice el nombre de los colores.
///
/// Usa el "texto a voz" del propio celular (funciona sin internet si el
/// celular tiene descargada la voz en español). Se busca una voz femenina en
/// español y se le sube el tono para que suene más infantil.
class Voz {
  Voz._();

  static final FlutterTts _tts = FlutterTts();
  static Future<bool>? _preparada;

  /// Deja la voz lista. Se puede llamar varias veces; solo prepara una vez.
  static Future<bool> preparar() => _preparada ??= _configurar();

  static Future<bool> _configurar() async {
    try {
      // Que speak() espere a que termine de hablar.
      await _tts.awaitSpeakCompletion(true);

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

  /// Calla la voz si está hablando.
  static Future<void> parar() async {
    try {
      await _tts.stop();
    } catch (_) {}
  }

  /// Dice [texto] y espera a que termine (máximo 3 segundos).
  /// [tono] permite una voz más aguda o más grave solo para esta frase.
  static Future<void> decir(String texto, {double? tono}) async {
    if (!Ajustes.vozActiva) return;
    final lista = await preparar();
    if (!lista) return;
    try {
      await _tts.stop();
      if (tono != null) await _tts.setPitch(tono);
      await _tts.speak(texto).timeout(const Duration(seconds: 3));
    } catch (_) {
      // Sin voz no pasa nada: la app sigue funcionando.
    } finally {
      if (tono != null) {
        try {
          await _tts.setPitch(Ajustes.vozTono);
        } catch (_) {}
      }
    }
  }
}
