import 'package:flutter/material.dart';

/// Botón redondo y grande, con un ícono, fácil de tocar para una niña pequeña.
class BotonGrande extends StatelessWidget {
  const BotonGrande({
    super.key,
    required this.icono,
    required this.color,
    required this.alTocar,
    this.tamano = 64,
  });

  final IconData icono;
  final Color color;
  final VoidCallback alTocar;
  final double tamano;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color,
      shape: const CircleBorder(),
      elevation: 3,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: alTocar,
        child: SizedBox(
          width: tamano,
          height: tamano,
          child: Center(
            child: Icon(icono, size: tamano * 0.58, color: Colors.white),
          ),
        ),
      ),
    );
  }
}
