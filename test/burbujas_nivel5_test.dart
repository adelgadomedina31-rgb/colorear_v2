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
      'Nivel 5: burbujas con animalitos que salen volando, y al terminar el '
      'nivel la celebración grande (cada 5 niveles)', (tester) async {
    sinAvisosDeSonido();
    await tester.binding.setSurfaceSize(const Size(420, 860));
    await tester.pumpWidget(
        const MaterialApp(home: BurbujasJuego(nivelInicial: 5, semilla: 9)));
    await tester.pump(const Duration(milliseconds: 100));
    final juego = juegoBurbujas(tester);
    expect(juego.plan!.cuantas(TipoBurbuja.animalito), 1);
    expect(frases.last, AjustesBurbujas.vozAnimalito);

    final conAnimal = await esperarBurbuja(tester, TipoBurbuja.animalito);
    expect(AjustesBurbujas.animalitos, contains(conAnimal.animal));
    await tocarBurbuja(tester, conAnimal);
    expect(juego.burbujas, isNot(contains(conAnimal)));
    expect(juego.animalesVolando, 1, reason: 'el animalito sale volando');
    await avanzar(tester, const Duration(seconds: 2));
    expect(juego.animalesVolando, 0, reason: 'y se va');

    // Termina el nivel 5: la celebración grande.
    await reventarTodas(tester);
    await avanzar(tester, const Duration(milliseconds: 600));
    expect(celebracion, findsOneWidget);
    expect(find.text(AjustesBurbujas.celebracionLinea1), findsOneWidget);
    expect(find.text(AjustesBurbujas.celebracionLinea2), findsOneWidget);
    await avanzar(tester, const Duration(seconds: 1));
    expect(frases.last, AjustesBurbujas.vozCelebracion);
    expect(juego.burbujas, isEmpty, reason: 'no salen mientras celebra');

    // Se quita sola y sigue el nivel 6.
    await avanzar(tester,
        const Duration(seconds: AjustesBurbujas.segundosCelebracionGrande));
    expect(celebracion, findsNothing);
    expect(juego.nivel, 6);
    expect(frases.last, '¡Nivel 6!');
    expect(find.text('NIVEL 6'), findsOneWidget);
    await cerrarPantalla(tester);
  });
}
