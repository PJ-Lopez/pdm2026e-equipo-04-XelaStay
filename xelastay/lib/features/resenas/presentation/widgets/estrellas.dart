import 'package:flutter/material.dart';

const colorEstrella = Color(0xFFE8A638);

/// Cinco estrellas de solo lectura. El lector de pantalla dice "4 de 5".
class Estrellas extends StatelessWidget {
  const Estrellas({super.key, required this.valor, this.tamano = 18});

  final int valor;
  final double tamano;

  @override
  Widget build(BuildContext context) => Semantics(
    label: '$valor de 5 estrellas',
    excludeSemantics: true,
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 1; i <= 5; i++)
          Icon(
            i <= valor ? Icons.star_rounded : Icons.star_outline_rounded,
            color: colorEstrella,
            size: tamano,
          ),
      ],
    ),
  );
}
