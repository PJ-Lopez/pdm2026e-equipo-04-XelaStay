import 'package:flutter/material.dart';

import '../../../../core/widgets/image_placeholder.dart';

/// Foto de portada de un alojamiento. Si no hay foto o falla la descarga,
/// muestra el marcador de la marca en lugar de un hueco.
class StayPhoto extends StatelessWidget {
  const StayPhoto({super.key, this.url});

  final String? url;

  @override
  Widget build(BuildContext context) {
    final foto = url;
    if (foto == null || foto.isEmpty) {
      return const ImagePlaceholder(
        label: 'Aquí va una imagen del alojamiento',
      );
    }
    return Image.network(
      foto,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) =>
          const ImagePlaceholder(label: 'Aquí va una imagen del alojamiento'),
      loadingBuilder: (context, child, progress) => progress == null
          ? child
          : const ImagePlaceholder(label: 'Cargando imagen', compact: true),
    );
  }
}
