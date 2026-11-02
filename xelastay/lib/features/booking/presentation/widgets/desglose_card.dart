import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/formatos.dart';
import '../../domain/entities/reserva.dart';

/// Desglose del precio: noches × precio, tarifa de servicio y total.
class DesgloseCard extends StatelessWidget {
  const DesgloseCard({
    super.key,
    required this.precioNocheCentavos,
    required this.desglose,
  });

  final int precioNocheCentavos;
  final Desglose desglose;

  @override
  Widget build(BuildContext context) {
    final noches = desglose.noches == 1
        ? '1 noche'
        : '${desglose.noches} noches';
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        children: [
          _Fila(
            '${quetzales(precioNocheCentavos)} × $noches',
            quetzales(desglose.subtotalCentavos),
          ),
          _Fila(
            'Tarifa de servicio (${Desglose.porcentajeServicio} %)',
            quetzales(desglose.servicioCentavos),
          ),
          const Divider(height: 20, color: AppColors.line),
          _Fila('Total', quetzales(desglose.totalCentavos), fuerte: true),
        ],
      ),
    );
  }
}

class _Fila extends StatelessWidget {
  const _Fila(this.concepto, this.monto, {this.fuerte = false});

  final String concepto;
  final String monto;
  final bool fuerte;

  @override
  Widget build(BuildContext context) {
    final estilo = TextStyle(
      color: AppColors.ink,
      fontWeight: fuerte ? FontWeight.w800 : FontWeight.w400,
      fontSize: fuerte ? 16 : 14,
    );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(child: Text(concepto, style: estilo)),
          Text(monto, style: estilo),
        ],
      ),
    );
  }
}
