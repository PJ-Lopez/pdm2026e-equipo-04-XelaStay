import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/formatos.dart';
import '../../../booking/domain/entities/reserva.dart';
import '../../../booking/presentation/providers/reservas_providers.dart';
import '../../../booking/presentation/widgets/estado_reserva_chip.dart';

/// Pestañas del panel del anfitrión.
enum FiltroSolicitudes { porAtender, aceptadas, cerradas }

/// En qué pestaña del panel cae una solicitud.
FiltroSolicitudes filtroDe(EstadoReserva estado) => switch (estado) {
  EstadoReserva.pendiente => FiltroSolicitudes.porAtender,
  EstadoReserva.aceptada ||
  EstadoReserva.confirmada => FiltroSolicitudes.aceptadas,
  EstadoReserva.rechazada ||
  EstadoReserva.cancelada ||
  EstadoReserva.completada => FiltroSolicitudes.cerradas,
};

/// Panel del anfitrión: solicitudes de reserva para aceptar, rechazar o
/// cerrar. Lee las solicitudes guardadas en este teléfono (ADR-0001).
class SolicitudesPage extends ConsumerStatefulWidget {
  const SolicitudesPage({super.key});

  @override
  ConsumerState<SolicitudesPage> createState() => _SolicitudesPageState();
}

class _SolicitudesPageState extends ConsumerState<SolicitudesPage> {
  var _filtro = FiltroSolicitudes.porAtender;
  // Evita dos toques sobre la misma solicitud mientras se guarda.
  final _ocupadas = <int>{};

  @override
  Widget build(BuildContext context) {
    final solicitudes = ref.watch(solicitudesProvider);
    final hoy = soloFecha(ref.watch(relojProvider)());
    return Scaffold(
      appBar: AppBar(title: const Text('Solicitudes de reserva')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
            child: SegmentedButton<FiltroSolicitudes>(
              segments: const [
                ButtonSegment(
                  value: FiltroSolicitudes.porAtender,
                  label: Text('Por atender'),
                ),
                ButtonSegment(
                  value: FiltroSolicitudes.aceptadas,
                  label: Text('Aceptadas'),
                ),
                ButtonSegment(
                  value: FiltroSolicitudes.cerradas,
                  label: Text('Cerradas'),
                ),
              ],
              selected: {_filtro},
              showSelectedIcon: false,
              onSelectionChanged: (s) => setState(() => _filtro = s.single),
            ),
          ),
          Expanded(
            child: solicitudes.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, _) => Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('No pudimos leer las solicitudes.'),
                    const SizedBox(height: 12),
                    FilledButton.tonalIcon(
                      onPressed: () => ref.invalidate(solicitudesProvider),
                      icon: const Icon(Icons.refresh),
                      label: const Text('Reintentar'),
                    ),
                  ],
                ),
              ),
              data: (todas) {
                final visibles = todas
                    .where((r) => filtroDe(r.estado) == _filtro)
                    .toList();
                if (visibles.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Text(
                        switch (_filtro) {
                          FiltroSolicitudes.porAtender =>
                            'No hay solicitudes por atender.',
                          FiltroSolicitudes.aceptadas =>
                            'Aún no has aceptado solicitudes.',
                          FiltroSolicitudes.cerradas =>
                            'Aquí verás las rechazadas, canceladas y '
                                'completadas.',
                        },
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: AppColors.muted),
                      ),
                    ),
                  );
                }
                return ListView(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                  children: [for (final r in visibles) _tarjeta(r, hoy)],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _tarjeta(Reserva r, DateTime hoy) {
    final ocupada = _ocupadas.contains(r.id);
    final noches = r.noches == 1 ? '1 noche' : '${r.noches} noches';
    return Card(
      elevation: 0,
      color: AppColors.surface,
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(color: AppColors.line),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(r.titulo, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 4),
            Text(
              '${r.huespedNombre} · ${r.huespedes} huésp. · '
              '${rangoFechas(r.entrada, r.salida)} · $noches',
              style: const TextStyle(color: AppColors.muted),
            ),
            Text(
              'Total ${quetzales(r.desglose.totalCentavos)}',
              style: const TextStyle(color: AppColors.muted),
            ),
            const SizedBox(height: 10),
            EstadoReservaChip(estado: r.estado),
            if (r.estado == EstadoReserva.pendiente) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: ocupada
                          ? null
                          : () => _ejecutar(
                              r,
                              () => ref
                                  .read(reservasRepositoryProvider)
                                  .rechazar(r.id),
                              () => 'Solicitud rechazada',
                            ),
                      child: const Text('Rechazar'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: FilledButton(
                      onPressed: ocupada ? null : () => _aceptar(r),
                      child: const Text('Aceptar'),
                    ),
                  ),
                ],
              ),
            ],
            if (r.estado == EstadoReserva.aceptada) ...[
              const SizedBox(height: 8),
              const Text(
                'Esperando el pago del huésped.',
                style: TextStyle(color: AppColors.muted),
              ),
            ],
            if (r.estado == EstadoReserva.confirmada &&
                !r.entrada.isAfter(hoy)) ...[
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: ocupada
                    ? null
                    : () => _ejecutar(
                        r,
                        () => ref
                            .read(reservasRepositoryProvider)
                            .completar(r.id),
                        () => 'Estadía completada',
                      ),
                icon: const Icon(Icons.flag_outlined),
                label: const Text('Marcar estadía completada'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _aceptar(Reserva r) async {
    final repositorio = ref.read(reservasRepositoryProvider);
    var rechazadas = 0;
    await _ejecutar(
      r,
      () async => rechazadas = await repositorio.aceptar(r.id),
      () => switch (rechazadas) {
        0 => 'Solicitud aceptada',
        1 => 'Aceptada. Se rechazó 1 solicitud de las mismas fechas.',
        _ =>
          'Aceptada. Se rechazaron $rechazadas solicitudes de las mismas '
              'fechas.',
      },
    );
  }

  /// Corre la acción, vuelve a leer de la base y avisa. Los errores de la
  /// regla se muestran tal cual; los demás, con un mensaje amigable.
  Future<void> _ejecutar(
    Reserva r,
    Future<void> Function() accion,
    String Function() exito,
  ) async {
    if (_ocupadas.contains(r.id)) return;
    final avisos = ScaffoldMessenger.of(context);
    setState(() => _ocupadas.add(r.id));
    try {
      await accion();
      if (!mounted) return;
      refrescarReservas(ref);
      avisos
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(exito())));
    } on ReservaException catch (e) {
      avisos
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(e.mensaje)));
    } catch (_) {
      avisos
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text('No pudimos guardar. Intenta de nuevo.'),
          ),
        );
    } finally {
      if (mounted) setState(() => _ocupadas.remove(r.id));
    }
  }
}
