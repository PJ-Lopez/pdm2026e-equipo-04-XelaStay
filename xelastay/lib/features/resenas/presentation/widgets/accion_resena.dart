import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../booking/domain/entities/reserva.dart';
import '../../domain/entities/resena.dart';
import '../pages/resena_page.dart';
import '../providers/resenas_providers.dart';
import 'estrellas.dart';

/// En el detalle de una estadía completada: el botón para reseñar o, si ya
/// se reseñó, la reseña que quedó guardada.
class AccionResena extends ConsumerWidget {
  const AccionResena({super.key, required this.reserva});

  final Reserva reserva;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final resena = ref.watch(resenaDeReservaProvider(reserva.id));
    return resena.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, _) => TextButton(
        onPressed: () => ref.invalidate(resenaDeReservaProvider(reserva.id)),
        child: const Text('No pudimos revisar tu reseña. Reintentar'),
      ),
      data: (r) => r == null
          ? FilledButton.icon(
              onPressed: () => _escribir(context),
              icon: const Icon(Icons.rate_review_outlined),
              label: const Text('Escribir reseña'),
            )
          : _TuResena(resena: r),
    );
  }

  Future<void> _escribir(BuildContext context) async {
    final avisos = ScaffoldMessenger.of(context);
    final publicada = await Navigator.of(context).push<Resena>(
      MaterialPageRoute<Resena>(builder: (_) => ResenaPage(reserva: reserva)),
    );
    if (publicada != null) {
      avisos.showSnackBar(
        const SnackBar(
          content: Text('Gracias. Tu reseña ya aparece en el alojamiento.'),
        ),
      );
    }
  }
}

class _TuResena extends StatelessWidget {
  const _TuResena({required this.resena});

  final Resena resena;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: AppColors.blueSoft,
      borderRadius: BorderRadius.circular(18),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Tu reseña', style: TextStyle(fontWeight: FontWeight.w700)),
        const SizedBox(height: 6),
        Row(
          children: [
            Estrellas(valor: resena.estrellas),
            const SizedBox(width: 6),
            Text(etiquetaEstrellas(resena.estrellas)),
          ],
        ),
        if (resena.comentario.isNotEmpty) ...[
          const SizedBox(height: 6),
          Text(resena.comentario),
        ],
      ],
    ),
  );
}
