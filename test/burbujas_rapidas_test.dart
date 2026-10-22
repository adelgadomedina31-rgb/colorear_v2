import 'package:colorear_ninos/juegos/burbujas/burbujas_ajustes.dart';
import 'package:colorear_ninos/juegos/burbujas/burbujas_juego.dart';
import 'package:colorear_ninos/juegos/burbujas/niveles.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'ayuda_juegos.dart';
import 'ayuda_pintar.dart';

void main() {
  setUp(prepararPrueba);

  testWidgets(
      'Nivel 9: burbujitas chiquitas y muy rápidas, que se atrapan con un '
      'toque aunque el dedo no caiga justo encima', (tester) async {
    sinAvisosDeSonido();
    await tester.binding.setSurfaceSize(const Size(420, 860));
    await tester.pumpWidget(
        const MaterialApp(home: BurbujasJuego(nivelInicial: 9, semilla: 4)));
    await tester.pump(const Duration(milliseconds: 100));
    final juego = juegoBurbujas(tester);
    expect(juego.plan!.cuantas(TipoBurbuja.rapida), 1);
    expect(frases.last, AjustesBurbujas.vozRapida);

    final rapida = await esperarBurbuja(tester, TipoBurbuja.rapida);
    final lado = zonaBurbujas(tester).size.shortestSide;
    // Más chiquita que la más chica de las normales.
    expect(rapida.radio * 2 / lado, lessThan(AjustesBurbujas.tamanoMinimo));
    // Más rápida que la más rápida de las normales (que van entre 0.7 y 1.3
    // veces la velocidad del nivel).
    final velocidadNivel = juego.plan!.velocidad * lado;
    expect(rapida.velocidad, greaterThan(velocidadNivel * 1.3));

    // Recorre mucho camino en un segundo.
    var camino = 0.0;
    var antes = rapida.centro;
    for (var k = 0; k < 25; k++) {
      await tester.pump(const Duration(milliseconds: 40));
      camino += (rapida.centro - antes).distance;
      antes = rapida.centro;
    }
    expect(camino, greaterThan(velocidadNivel * 1.3 * 0.75));

    // Un toque un poquito al lado también la atrapa.
    final cerca = dondeEsta(tester, rapida) + Offset(rapida.radio + 8, 0);
    final otraMasCerca = juego.burbujas.any((b) =>
        b != rapida &&
        (dondeEsta(tester, b) - cerca).distance < b.radio * 1.15 + 18);
    if (!otraMasCerca) {
      final hechas = juego.reventadas;
      await tester.tapAt(cerca);
      await tester.pump(const Duration(milliseconds: 40));
      expect(juego.burbujas, isNot(contains(rapida)));
      expect(juego.reventadas, hechas + 1);
    }

    await reventarTodas(tester);
    await avanzar(tester, const Duration(seconds: 3));
    expect(juego.nivel, 10);
    await cerrarPantalla(tester);
  });
}
