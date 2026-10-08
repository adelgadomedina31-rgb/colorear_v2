import 'package:flutter/material.dart';

import '../config.dart';
import '../data/repositorio.dart';
import '../models/dibujo.dart';
import '../models/pintura.dart';
import '../widgets/lienzo.dart';
import 'pantalla_padres.dart';
import 'pantalla_pintar.dart';

/// Menú principal: una cuadrícula de dibujos. Tocar uno lo abre para pintar.
/// El engranaje de la esquina (mantenerlo presionado) abre la Zona de papás.
class PantallaInicio extends StatefulWidget {
  const PantallaInicio({super.key});

  @override
  State<PantallaInicio> createState() => _EstadoInicio();
}

class _EstadoInicio extends State<PantallaInicio> {
  static const List<Color> _bordes = <Color>[
    Color(0xFFE53935),
    Color(0xFFFB8C00),
    Color(0xFF7CB342),
    Color(0xFF1E88E5),
    Color(0xFF8E24AA),
    Color(0xFFEC407A),
  ];

  final ScrollController _scroll = ScrollController();
  List<Dibujo> _dibujos = <Dibujo>[];
  bool _cargando = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _cargar() async {
    try {
      final lista = await Repositorio.cargarTodos();
      // Lo que se pintó antes (aunque la app se haya cerrado).
      await Pintura.cargar(lista);
      if (!mounted) return;
      setState(() {
        _dibujos = lista;
        _cargando = false;
        _error = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'No pude cargar los dibujos: $e';
        _cargando = false;
      });
    }
  }

  Future<void> _abrirDibujo(int indice) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => PantallaPintar(dibujos: _dibujos, indice: indice),
      ),
    );
    // Al volver, se refrescan las miniaturas para mostrar lo pintado.
    if (mounted) setState(() {});
  }

  Future<void> _abrirZonaPadres() async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(builder: (_) => const PantallaPadres()),
    );
    if (mounted) _cargar();
  }

  Widget _contenido() {
    if (_cargando) {
      return const Center(child: CircularProgressIndicator());
    }
    final error = _error;
    if (error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(error, textAlign: TextAlign.center),
        ),
      );
    }
    // Con muchos dibujos el menú se desliza hacia arriba/abajo con el dedo.
    // La barra de la derecha le muestra a quien mira en qué parte de la lista va.
    return Scrollbar(
      controller: _scroll,
      thumbVisibility: true,
      thickness: 6,
      radius: const Radius.circular(8),
      child: GridView.builder(
        controller: _scroll,
        cacheExtent: 800,
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
        ),
        itemCount: _dibujos.length,
        itemBuilder: (context, i) => _Tarjeta(
          dibujo: _dibujos[i],
          borde: _bordes[i % _bordes.length],
          alTocar: () => _abrirDibujo(i),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Ajustes.fondoApp,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 8, 4),
              child: Row(
                children: [
                  const Expanded(child: _Titulo()),
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onLongPress: _abrirZonaPadres,
                    child: const Padding(
                      padding: EdgeInsets.all(14),
                      child: Icon(
                        Icons.settings_rounded,
                        size: 26,
                        color: Colors.black26,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(child: _contenido()),
          ],
        ),
      ),
    );
  }
}

class _Titulo extends StatelessWidget {
  const _Titulo();

  static const List<Color> _colores = <Color>[
    Color(0xFFE53935),
    Color(0xFFFB8C00),
    Color(0xFF43A047),
    Color(0xFF1E88E5),
    Color(0xFF8E24AA),
    Color(0xFFEC407A),
  ];

  @override
  Widget build(BuildContext context) {
    const texto = 'COLOREA ARLETH';
    final letras = <TextSpan>[];
    var n = 0; // cuenta solo las letras, para que los colores no salten con el espacio
    for (var i = 0; i < texto.length; i++) {
      final letra = texto[i];
      if (letra == ' ') {
        letras.add(const TextSpan(text: ' '));
      } else {
        letras.add(
          TextSpan(
            text: letra,
            style: TextStyle(color: _colores[n % _colores.length]),
          ),
        );
        n++;
      }
    }
    // FittedBox: si el celular es angosto, el título se achica en vez de cortarse.
    return FittedBox(
      fit: BoxFit.scaleDown,
      alignment: Alignment.centerLeft,
      child: Text.rich(
        TextSpan(
          style: const TextStyle(
            fontSize: 40,
            fontWeight: FontWeight.w900,
            letterSpacing: 1,
          ),
          children: letras,
        ),
        maxLines: 1,
        softWrap: false,
      ),
    );
  }
}

class _Tarjeta extends StatelessWidget {
  const _Tarjeta({
    required this.dibujo,
    required this.borde,
    required this.alTocar,
  });

  final Dibujo dibujo;
  final Color borde;
  final VoidCallback alTocar;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      elevation: 3,
      borderRadius: BorderRadius.circular(28),
      child: InkWell(
        borderRadius: BorderRadius.circular(28),
        onTap: alTocar,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: borde, width: 6),
          ),
          padding: const EdgeInsets.all(10),
          child: CustomPaint(
            painter: DibujoPainter(
              dibujo: dibujo,
              pintura: Pintura.de(dibujo),
            ),
          ),
        ),
      ),
    );
  }
}
