import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/formatos.dart';
import '../../../stays/domain/entities/stay.dart';
import '../../domain/calificacion.dart';
import '../../domain/entities/resena.dart';
import '../providers/resenas_providers.dart';
import 'estrellas.dart';

/// Promedio del alojamiento: lo del catálogo más lo reseñado en la app.
/// Mientras cargan las reseñas se muestra lo del catálogo.
class CalificacionDelAlojamiento extends ConsumerWidget {
  const CalificacionDelAlojamiento({super.key, required this.stay});

  final Stay stay;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locales = ref.watch(resenasDeAlojamientoProvider(stay.id)).value;
    final calificacion = Calificacion.combinar(
      promedioCatalogo: stay.ratingAverage,
      cantidadCatalogo: stay.ratingCount,
      locales: locales ?? const [],
    );
    if (calificacion.vacia) {
      return Text(
        calificacion.texto,
        style: const TextStyle(color: AppColors.muted),
      );
    }
    return Row(
      children: [
        const Icon(Icons.star_rounded, color: colorEstrella, size: 20),
        const SizedBox(width: 4),
        Text(
          calificacion.texto,
          style: const TextStyle(
            color: AppColors.ink,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

/// Lista de reseñas escritas por huéspedes que completaron su estadía.
class ResenasDelAlojamiento extends ConsumerWidget {
  const ResenasDelAlojamiento({super.key, required this.stay});

  final Stay stay;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final resenas = ref.watch(resenasDeAlojamientoProvider(stay.id));
    return resenas.when(
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: 12),
        child: LinearProgressIndicator(),
      ),
      error: (_, _) => TextButton(
        onPressed: () => ref.invalidate(resenasDeAlojamientoProvider(stay.id)),
        child: const Text('No pudimos leer las reseñas. Reintentar'),
      ),
      data: (lista) => lista.isEmpty
          ? const SizedBox.shrink()
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Reseñas de huéspedes',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                for (final r in lista) _ResenaTile(resena: r),
              ],
            ),
    );
  }
}

class _ResenaTile extends StatelessWidget {
  const _ResenaTile({required this.resena});

  final Resena resena;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    margin: const EdgeInsets.only(bottom: 10),
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: AppColors.line),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                resena.autor,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
            Text(
              fechaCorta(resena.creadaEn),
              style: const TextStyle(color: AppColors.muted, fontSize: 12),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            Estrellas(valor: resena.estrellas),
            const SizedBox(width: 6),
            Text(
              etiquetaEstrellas(resena.estrellas),
              style: const TextStyle(color: AppColors.muted),
            ),
          ],
        ),
        if (resena.comentario.isNotEmpty) ...[
          const SizedBox(height: 6),
          Text(resena.comentario),
        ],
        const SizedBox(height: 8),
        const Row(
          children: [
            Icon(Icons.verified_outlined, size: 16, color: AppColors.success),
            SizedBox(width: 4),
            Text(
              'Estadía verificada',
              style: TextStyle(color: AppColors.success, fontSize: 12),
            ),
          ],
        ),
      ],
    ),
  );
}
