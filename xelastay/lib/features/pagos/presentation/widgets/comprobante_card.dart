import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/formatos.dart';
import '../providers/pagos_providers.dart';

/// Comprobante del pago de una reserva. Si todavía no hay pago, no ocupa
/// espacio.
class ComprobanteCard extends ConsumerWidget {
  const ComprobanteCard({super.key, required this.reservaId});

  final int reservaId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pago = ref.watch(pagoDeReservaProvider(reservaId));
    return pago.when(
      loading: () => const SizedBox.shrink(),
      error: (_, _) => TextButton(
        onPressed: () => ref.invalidate(pagoDeReservaProvider(reservaId)),
        child: const Text('No pudimos leer el comprobante. Reintentar'),
      ),
      data: (p) => p == null
          ? const SizedBox.shrink()
          : Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFE8F3EE),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppColors.line),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.receipt_long_outlined,
                        color: AppColors.success,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Comprobante ${p.referencia}',
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text('Pagado con ${p.metodo.etiqueta}'),
                  Text('Total ${quetzales(p.totalCentavos)}'),
                  Text(
                    fechaHora(p.pagadoEn),
                    style: const TextStyle(color: AppColors.muted),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Pago simulado: no se hizo ningún cobro real.',
                    style: TextStyle(color: AppColors.muted, fontSize: 12),
                  ),
                ],
              ),
            ),
    );
  }
}
