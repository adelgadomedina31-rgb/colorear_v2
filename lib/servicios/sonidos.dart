import 'dart:async';
import 'dart:math' as math;

import 'package:audioplayers/audioplayers.dart';

import '../config.dart';

/// El "plop" que suena al pintar. Los archivos están en assets/sonidos/
/// (se crean con tools/generar_sonidos.py).
///
/// Para que no se trabe con el uso: los sonidos se cargan UNA sola vez al
/// entrar a pintar, se reutilizan siempre los mismos reproductores y se
/// ignoran los plops demasiado seguidos.
class Sonidos {
  Sonidos._();

  static const List<String> _archivos = <String>[
    'sonidos/plop1.wav',
    'sonidos/plop2.wav',
    'sonidos/plop3.wav',
  ];

  /// Reproductores por sonido (2 de cada uno, para que puedan sonar seguidos).
  static const int _copias = 2;

  static List<List<AudioPlayer>>? _reproductores;
  static Future<bool>? _preparado;
  static final List<int> _turnos = List<int>.filled(_archivos.length, 0);
  static final math.Random _azar = math.Random();
  static final Stopwatch _reloj = Stopwatch()..start();
  static int _ultimo = -1000;
  static int _noAntesDe = 0; // si falló la carga, no reintentar enseguida

  /// Carga los sonidos (una sola vez). Si falla, se reintenta más tarde.
  static Future<bool> preparar() {
    final existente = _preparado;
    if (existente != null) return existente;
    if (_reloj.elapsedMilliseconds < _noAntesDe) return Future<bool>.value(false);
    final nuevo = _cargar();
    _preparado = nuevo;
    nuevo.then((bien) {
      if (!bien) {
        _preparado = null;
        _noAntesDe = _reloj.elapsedMilliseconds + 30000;
      }
    });
    return nuevo;
  }

  static Future<bool> _cargar() async {
    final creados = <AudioPlayer>[];
    const espera = Duration(seconds: 3);
    try {
      // Que el plop no le quite el sonido a la voz ni a otras apps.
      final contexto = AudioContext(
        android: AudioContextAndroid(audioFocus: AndroidAudioFocus.none),
      );
      final todos = <List<AudioPlayer>>[];
      for (final archivo in _archivos) {
        final grupo = <AudioPlayer>[];
        for (var c = 0; c < _copias; c++) {
          final reproductor = AudioPlayer();
          creados.add(reproductor);
          await reproductor.setAudioContext(contexto).timeout(espera);
          await reproductor.setPlayerMode(PlayerMode.lowLatency).timeout(espera);
          await reproductor.setReleaseMode(ReleaseMode.stop).timeout(espera);
          await reproductor.setVolume(Ajustes.volumenPintar).timeout(espera);
          await reproductor.setSource(AssetSource(archivo)).timeout(espera);
          grupo.add(reproductor);
        }
        todos.add(grupo);
      }
      _reproductores = todos;
      return true;
    } catch (_) {
      for (final reproductor in creados) {
        unawaited(reproductor.dispose().catchError((Object _) {}));
      }
      return false;
    }
  }

  /// Un "plop" de burbuja (uno de tres tonos al azar). No espera a nada:
  /// si el sonido no está listo o hay demasiados seguidos, simplemente no suena.
  static void plop() {
    if (!Ajustes.sonidoPintar) return;
    final ahora = _reloj.elapsedMilliseconds;
    if (ahora - _ultimo < 90) return;
    _ultimo = ahora;
    final reproductores = _reproductores;
    if (reproductores == null) {
      preparar();
      return;
    }
    final s = _azar.nextInt(reproductores.length);
    final grupo = reproductores[s];
    final reproductor = grupo[_turnos[s]];
    _turnos[s] = (_turnos[s] + 1) % grupo.length;
    unawaited(_sonar(reproductor));
  }

  static Future<void> _sonar(AudioPlayer reproductor) async {
    try {
      await reproductor.stop().timeout(const Duration(milliseconds: 500));
      await reproductor.resume().timeout(const Duration(milliseconds: 500));
    } catch (_) {
      // Sin sonido no pasa nada: se sigue pintando.
    }
  }
}
