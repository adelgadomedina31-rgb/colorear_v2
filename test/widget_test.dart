import 'dart:ui';

import 'package:colorear_ninos/models/dibujo.dart';
import 'package:colorear_ninos/models/pintura.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const texto = '{"id":"cuadro","nombre":"Cuadro","regiones":['
      '{"id":"a","path":"M 100 100 L 500 100 L 500 500 L 100 500 Z"},'
      '{"id":"b","path":"M 100 100 L 300 100 L 300 500 L 100 500 Z"}]}';

  test('un dibujo se lee y sus regiones saben si les tocan un punto', () {
    final dibujo = Dibujo.desdeTexto(texto);
    expect(dibujo.nombre, 'Cuadro');
    expect(dibujo.regiones.length, 2);
    expect(dibujo.regiones.first.path.contains(const Offset(300, 300)), isTrue);
    expect(dibujo.regiones.first.path.contains(const Offset(700, 700)), isFalse);
  });

  test('el área visible descuenta lo que tapan las regiones de encima', () {
    final dibujo = Dibujo.desdeTexto(texto);
    // "a" mide 400 x 400 pero "b" (encima) le tapa la mitad.
    expect(dibujo.areaVisible(0), closeTo(80000, 2000));
    expect(dibujo.areaVisible(1), closeTo(80000, 2000));
  });

  test('un trazo guardado por la versión anterior se puede leer', () {
    final copia = Trazo.desdeJson(<String, Object>{
      'c': 0xFFE53935,
      'r': 120,
      's': 42,
      'p': <double>[200, 300, 260, 330],
    }, 0);
    expect(copia, isNotNull);
    expect(copia!.color, const Color(0xFFE53935));
    expect(copia.radio, 120);
    expect(copia.semilla, 42);
    expect(copia.puntos, const <Offset>[Offset(200, 300), Offset(260, 330)]);
    expect(copia.limites().contains(const Offset(200, 300)), isTrue);
  });

  test('un texto roto da un error entendible', () {
    expect(() => Dibujo.desdeTexto('hola'), throwsFormatException);
  });
}
