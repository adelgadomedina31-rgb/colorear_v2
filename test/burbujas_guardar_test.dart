import 'package:colorear_ninos/juegos/burbujas/burbujas_ajustes.dart';
import 'package:colorear_ninos/juegos/burbujas/burbujas_juego.dart';
import 'package:colorear_ninos/juegos/burbujas/burbujas_papas.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'ayuda_juegos.dart';
import 'ayuda_pintar.dart';

void main() {
  setUp(prepararPrueba);

  testWidgets(
      'Burbujas recuerda el nivel: al volver a entrar sigue donde quedó, y '
      'en Ajustes se puede volver al nivel 1', (tester) async {
    sinAvisosDeSonido();
    SharedPreferences.setMockInitialValues(<String, Object>{
      'burbujas_nivel': 7,
    });
    await tester.binding.setSurfaceSize(const Size(420, 860));
    await tester.pumpWidget(const MaterialApp(home: BurbujasJuego(semilla: 3)));
    await tester.pump(const Duration(milliseconds: 100));

    // Sigue en el nivel 7 (donde salen las mega burbujas por primera vez:
    // la voz las presenta).
    expect(juegoBurbujas(tester).nivel, 7);
    expect(find.text('NIVEL 7'), findsOneWidget);
    expect(frases.last, AjustesBurbujas.vozMega);
    await cerrarPantalla(tester);

    // En Ajustes (zona de papás) dice en qué nivel va.
    await tester
        .pumpWidget(const MaterialApp(home: Scaffold(body: BurbujasPapas())));
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('Va en el nivel 7.'), findsOneWidget);

    // "Volver al nivel 1".
    await tester.tap(find.byKey(const ValueKey<String>('burbujas_reiniciar')));
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('Va en el nivel 1.'), findsOneWidget);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getInt('burbujas_nivel'), 1);
    final boton = tester.widget<ButtonStyleButton>(
        find.byKey(const ValueKey<String>('burbujas_reiniciar')));
    expect(boton.onPressed, isNull, reason: 'ya está en el 1');

    // Al entrar de nuevo, empieza en el nivel 1.
    await tester.pumpWidget(const MaterialApp(home: BurbujasJuego(semilla: 3)));
    await tester.pump(const Duration(milliseconds: 100));
    expect(juegoBurbujas(tester).nivel, 1);
    expect(find.text('NIVEL 1'), findsOneWidget);
    await cerrarPantalla(tester);
  });
}
