import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;
import 'package:shared_preferences/shared_preferences.dart';

import '../models/dibujo.dart';
import '../models/pintura.dart';

/// De dónde salen los dibujos:
///  - los que vienen con la app (carpeta assets/drawings, listados en indice.json)
///  - los que se agregan desde la "Zona de papás" (se guardan en el celular)
class Repositorio {
  Repositorio._();

  static const String _claveImportados = 'dibujos_importados';

  static Future<List<Dibujo>> cargarIncluidos() async {
    final indice = await rootBundle.loadString('assets/drawings/indice.json');
    final nombres = (jsonDecode(indice) as List<dynamic>).cast<String>();
    // Se leen todos los archivos a la vez (más rápido que uno por uno).
    final textos = await Future.wait(
      nombres.map((nombre) => rootBundle.loadString('assets/drawings/$nombre')),
    );
    return textos.map((texto) => Dibujo.desdeTexto(texto)).toList();
  }

  static Future<List<Dibujo>> cargarImportados() async {
    final prefs = await SharedPreferences.getInstance();
    final textos = prefs.getStringList(_claveImportados) ?? <String>[];
    final lista = <Dibujo>[];
    for (final texto in textos) {
      try {
        lista.add(Dibujo.desdeTexto(texto, importado: true));
      } catch (_) {
        // Un dibujo dañado no debe impedir que se vean los demás.
      }
    }
    return lista;
  }

  static Future<List<Dibujo>> cargarTodos() async {
    final incluidos = await cargarIncluidos();
    final importados = await cargarImportados();
    return <Dibujo>[...incluidos, ...importados];
  }

  /// Guarda un dibujo nuevo. Si ya había uno agregado con el mismo "id", lo reemplaza.
  /// Lanza FormatException (con mensaje legible) si el texto no sirve.
  static Future<Dibujo> importar(String texto) async {
    final dibujo = Dibujo.desdeTexto(texto, importado: true);
    final incluidos = await cargarIncluidos();
    if (incluidos.any((d) => d.id == dibujo.id)) {
      throw FormatException(
          'Ya hay un dibujo de la app con el id "${dibujo.id}". '
          'Cámbiale el "id" por otro (por ejemplo "${dibujo.id}2").');
    }
    final prefs = await SharedPreferences.getInstance();
    final textos = prefs.getStringList(_claveImportados) ?? <String>[];
    final nuevos = <String>[];
    for (final t in textos) {
      if (_idDe(t) != dibujo.id) nuevos.add(t);
    }
    nuevos.add(texto.trim());
    await prefs.setStringList(_claveImportados, nuevos);
    Pintura.borrar(dibujo);
    return dibujo;
  }

  static Future<void> borrarImportado(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final textos = prefs.getStringList(_claveImportados) ?? <String>[];
    final restantes = <String>[];
    for (final t in textos) {
      if (_idDe(t) != id) restantes.add(t);
    }
    await prefs.setStringList(_claveImportados, restantes);
    Pintura.borrarId(id);
  }

  static String? _idDe(String texto) {
    try {
      final datos = jsonDecode(texto);
      if (datos is Map<String, dynamic>) {
        final id = datos['id'];
        if (id is String) return id.trim();
      }
    } catch (_) {}
    return null;
  }
}
