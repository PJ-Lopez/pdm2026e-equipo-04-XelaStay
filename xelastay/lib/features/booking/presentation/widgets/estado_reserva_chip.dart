import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/reserva.dart';

/// Estado de una reserva con icono y texto: no depende solo del color.
class EstadoReservaChip extends StatelessWidget {
  const EstadoReservaChip({super.key, required this.estado});

  final EstadoReserva estado;

  @override
  Widget build(BuildContext context) {
    final (icono, color) = switch (estado) {
      EstadoReserva.pendiente => (Icons.hourglass_top, const Color(0xFF946318)),
      EstadoReserva.aceptada => (Icons.payments_outlined, AppColors.blue),
      EstadoReserva.confirmada => (
        Icons.check_circle_outline,
        AppColors.success,
      ),
      EstadoReserva.rechazada => (Icons.block, AppColors.red),
      EstadoReserva.cancelada => (Icons.cancel_outlined, AppColors.muted),
      EstadoReserva.completada => (Icons.flag_outlined, AppColors.muted),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icono, size: 16, color: color),
          const SizedBox(width: 5),
          Text(
            estado.etiqueta,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
