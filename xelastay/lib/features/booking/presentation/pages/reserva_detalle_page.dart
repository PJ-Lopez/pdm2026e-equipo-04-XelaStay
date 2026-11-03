import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/formatos.dart';
import '../../../chat/domain/entities/mensaje.dart';
import '../../../chat/presentation/pages/chat_page.dart';
import '../../../pagos/domain/entities/pago.dart';
import '../../../pagos/presentation/pages/pago_page.dart';
import '../../../pagos/presentation/widgets/comprobante_card.dart';
import '../../../resenas/presentation/widgets/accion_resena.dart';
import '../../domain/entities/reserva.dart';
import '../providers/reservas_providers.dart';
import '../widgets/desglose_card.dart';
import '../widgets/estado_reserva_chip.dart';

/// Detalle de una reserva. Siempre la vuelve a leer de la base, así que
/// después de cada acción muestra el estado real.
class ReservaDetallePage extends ConsumerWidget {
  const ReservaDetallePage({super.key, required this.reservaId});

  final int reservaId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reserva = ref.watch(reservaPorIdProvider(reservaId));
    final cargada = reserva.value;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reserva'),
        actions: [
          if (cargada != null)
            IconButton(
              tooltip: 'Chat con el anfitrión',
              icon: const Icon(Icons.chat_bubble_outline),
              onPressed: () => Navigator.of(context).push<void>(
                MaterialPageRoute<void>(
                  builder: (_) => ChatPage(
                    reserva: cargada,
                    comoAutor: AutorMensaje.huesped,
                  ),
                ),
              ),
            ),
        ],
      ),
      body: reserva.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => Center(
          child: TextButton(
            onPressed: () => ref.invalidate(reservaPorIdProvider(reservaId)),
            child: const Text('No pudimos leer la reserva. Reintentar'),
          ),
        ),
        data: (r) => ListView(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
          children: [
            Text(r.titulo, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 4),
            Text(r.zona, style: const TextStyle(color: AppColors.muted)),
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.blueSoft,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  EstadoReservaChip(estado: r.estado),
                  const SizedBox(height: 8),
                  Text(r.estado.descripcion),
                ],
              ),
            ),
            const SizedBox(height: 18),
            _Dato(
              icono: Icons.login,
              texto: 'Llegada: ${fechaCorta(r.entrada)} ${r.entrada.year}',
            ),
            _Dato(
              icono: Icons.logout,
              texto: 'Salida: ${fechaCorta(r.salida)} ${r.salida.year}',
            ),
            _Dato(
              icono: Icons.people_outline,
              texto: r.huespedes == 1
                  ? '1 huésped'
                  : '${r.huespedes} huéspedes',
            ),
            const SizedBox(height: 14),
            DesgloseCard(
              precioNocheCentavos: r.precioNocheCentavos,
              desglose: r.desglose,
            ),
            if (r.estado == EstadoReserva.confirmada ||
                r.estado == EstadoReserva.completada) ...[
              const SizedBox(height: 14),
              ComprobanteCard(reservaId: r.id),
            ],
            const SizedBox(height: 18),
            ..._acciones(context, ref, r),
          ],
        ),
      ),
    );
  }

  /// Lo que la persona puede hacer según el estado de la reserva.
  List<Widget> _acciones(BuildContext context, WidgetRef ref, Reserva r) => [
    if (r.estado == EstadoReserva.aceptada) ...[
      FilledButton.icon(
        onPressed: () => _pagar(context, r),
        icon: const Icon(Icons.lock_outline),
        label: const Text('Pagar y confirmar'),
      ),
      const SizedBox(height: 10),
    ],
    if (r.estado == EstadoReserva.completada) AccionResena(reserva: r),
    if (r.estado.cancelable)
      OutlinedButton.icon(
        onPressed: () => _cancelar(context, ref, r),
        style: OutlinedButton.styleFrom(foregroundColor: AppColors.red),
        icon: const Icon(Icons.cancel_outlined),
        label: const Text('Cancelar solicitud'),
      ),
  ];

  Future<void> _pagar(BuildContext context, Reserva r) async {
    final avisos = ScaffoldMessenger.of(context);
    final pago = await Navigator.of(
      context,
    ).push<Pago>(MaterialPageRoute<Pago>(builder: (_) => PagoPage(reserva: r)));
    if (pago != null) {
      avisos.showSnackBar(
        const SnackBar(
          content: Text('Pago registrado. Tu estadía está confirmada.'),
        ),
      );
    }
  }

  Future<void> _cancelar(BuildContext context, WidgetRef ref, Reserva r) async {
    final avisos = ScaffoldMessenger.of(context);
    final repositorio = ref.read(reservasRepositoryProvider);
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (contexto) => AlertDialog(
        title: const Text('¿Cancelar la solicitud?'),
        content: Text('Se cancelará tu reserva en "${r.titulo}".'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(contexto).pop(false),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () => Navigator.of(contexto).pop(true),
            child: const Text('Sí, cancelar'),
          ),
        ],
      ),
    );
    if (confirmar != true || !context.mounted) return;
    try {
      await repositorio.cancelar(r.id);
      if (!context.mounted) return;
      refrescarReservas(ref);
      avisos.showSnackBar(const SnackBar(content: Text('Solicitud cancelada')));
    } on ReservaException catch (e) {
      avisos.showSnackBar(SnackBar(content: Text(e.mensaje)));
    } catch (_) {
      avisos.showSnackBar(
        const SnackBar(content: Text('No pudimos cancelar. Intenta de nuevo.')),
      );
    }
  }
}

class _Dato extends StatelessWidget {
  const _Dato({required this.icono, required this.texto});

  final IconData icono;
  final String texto;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 5),
    child: Row(
      children: [
        Icon(icono, size: 20, color: AppColors.blue),
        const SizedBox(width: 10),
        Expanded(child: Text(texto)),
      ],
    ),
  );
}
