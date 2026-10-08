import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/repositorio.dart';
import '../models/dibujo.dart';

/// Zona de papás: aquí se agregan dibujos nuevos pegando su texto (JSON)
/// y se borran los que ya no se quieren.
class PantallaPadres extends StatefulWidget {
  const PantallaPadres({super.key});

  @override
  State<PantallaPadres> createState() => _EstadoPadres();
}

class _EstadoPadres extends State<PantallaPadres> {
  final TextEditingController _controlador = TextEditingController();
  List<Dibujo> _importados = <Dibujo>[];
  String? _mensaje;
  bool _esError = false;

  @override
  void initState() {
    super.initState();
    _recargar();
  }

  @override
  void dispose() {
    _controlador.dispose();
    super.dispose();
  }

  Future<void> _recargar() async {
    final lista = await Repositorio.cargarImportados();
    if (!mounted) return;
    setState(() => _importados = lista);
  }

  Future<void> _pegar() async {
    final datos = await Clipboard.getData(Clipboard.kTextPlain);
    if (!mounted) return;
    final texto = datos?.text;
    if (texto == null || texto.trim().isEmpty) {
      setState(() {
        _mensaje = 'No hay nada copiado todavía.';
        _esError = true;
      });
      return;
    }
    setState(() {
      _controlador.text = texto;
      _mensaje = null;
    });
  }

  Future<void> _guardar() async {
    final texto = _controlador.text;
    if (texto.trim().isEmpty) {
      setState(() {
        _mensaje = 'Primero pega el texto del dibujo.';
        _esError = true;
      });
      return;
    }
    try {
      final dibujo = await Repositorio.importar(texto);
      if (!mounted) return;
      _controlador.clear();
      setState(() {
        _mensaje = 'Listo: "${dibujo.nombre}" ya está en el menú.';
        _esError = false;
      });
      await _recargar();
    } on FormatException catch (e) {
      if (!mounted) return;
      setState(() {
        _mensaje = e.message;
        _esError = true;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _mensaje = 'No pude guardar ese dibujo. Revisa que esté completo.';
        _esError = true;
      });
    }
  }

  Future<void> _borrar(Dibujo dibujo) async {
    await Repositorio.borrarImportado(dibujo.id);
    if (!mounted) return;
    setState(() {
      _mensaje = 'Se borró "${dibujo.nombre}".';
      _esError = false;
    });
    await _recargar();
  }

  @override
  Widget build(BuildContext context) {
    final mensaje = _mensaje;
    return Scaffold(
      appBar: AppBar(title: const Text('Zona de papás')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Agregar un dibujo nuevo',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          const Text(
            'Copia el texto completo del dibujo, toca "Pegar" y luego "Guardar". '
            'El dibujo aparece al final del menú.',
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _controlador,
            minLines: 4,
            maxLines: 8,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              hintText: '{"id": "gato", "nombre": "Gato", ...}',
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _pegar,
                  icon: const Icon(Icons.content_paste_rounded),
                  label: const Text('Pegar'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton.icon(
                  onPressed: _guardar,
                  icon: const Icon(Icons.save_rounded),
                  label: const Text('Guardar'),
                ),
              ),
            ],
          ),
          if (mensaje != null) ...[
            const SizedBox(height: 12),
            Text(
              mensaje,
              style: TextStyle(
                color: _esError ? Colors.red.shade700 : Colors.green.shade800,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
          const SizedBox(height: 28),
          const Text(
            'Dibujos que agregaste',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          if (_importados.isEmpty)
            const Text('Todavía no has agregado ninguno.')
          else
            for (final dibujo in _importados)
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(dibujo.nombre),
                subtitle: Text(dibujo.id),
                trailing: IconButton(
                  tooltip: 'Borrar',
                  icon: const Icon(Icons.delete_outline_rounded),
                  onPressed: () => _borrar(dibujo),
                ),
              ),
        ],
      ),
    );
  }
}
