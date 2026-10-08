import 'dart:math' as math;

import 'package:audioplayers/audioplayers.dart';

import '../config.dart';

/// Los sonidos de la app: el "plop" al pintar y la música de la presentación.
/// Los archivos están en assets/sonidos/ (se crean con tools/generar_sonidos.py).
class Sonidos {
  Sonidos._();

  static const List<String> _plops = <String>[
    'sonidos/plop1.wav',
    'sonidos/plop2.wav',
    'sonidos/plop3.wav',
  ];

  /// Varios reproductores, para que un plop no corte al anterior.
  static final List<AudioPlayer> _reproductores =
      List<AudioPlayer>.generate(4, (_) => AudioPlayer());
  static int _siguiente = 0;
  static final math.Random _azar = math.Random();

  static AudioPlayer? _musica;
  static Future<void>? _configurado;

  /// Que los sonidos se mezclen entre sí (y con la voz) sin cortarse.
  static Future<void> _configurar() => _configurado ??= () async {
        try {
          final contexto = AudioContext(
            android: AudioContextAndroid(audioFocus: AndroidAudioFocus.none),
          );
          for (final r in _reproductores) {
            await r.setAudioContext(contexto);
          }
        } catch (_) {}
      }();

  /// Un "plop" de burbuja (con uno de tres tonos al azar).
  /// [suave] = más bajito (se usa mientras se arrastra el dedo).
  static Future<void> plop({bool suave = false}) async {
    if (!Ajustes.sonidoPintar) return;
    try {
      await _configurar();
      final reproductor = _reproductores[_siguiente];
      _siguiente = (_siguiente + 1) % _reproductores.length;
      final volumen = Ajustes.volumenPintar * (suave ? 0.55 : 1.0);
      await reproductor.play(
        AssetSource(_plops[_azar.nextInt(_plops.length)]),
        volume: volumen,
        mode: PlayerMode.lowLatency,
      );
    } catch (_) {
      // Sin sonido no pasa nada: se sigue pintando.
    }
  }

  /// La musiquita de la presentación.
  static Future<void> musicaPresentacion() async {
    try {
      final musica = _musica ??= AudioPlayer();
      await musica.play(AssetSource('sonidos/presentacion.wav'), volume: 0.8);
    } catch (_) {}
  }

  static Future<void> pararMusica() async {
    try {
      await _musica?.stop();
    } catch (_) {}
  }
}
