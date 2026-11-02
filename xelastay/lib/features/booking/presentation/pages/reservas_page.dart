import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/formatos.dart';
import '../../../auth/domain/entities/app_user.dart';
import '../../domain/entities/reserva.dart';
import '../providers/reservas_providers.dart';
import '../widgets/estado_reserva_chip.dart';
import 'reserva_detalle_page.dart';

/// Pestaña Reservas: las solicitudes y estadías de la persona, con filtro
/// Pendientes / Próximas / Anteriores.
class ReservasPage extends ConsumerStatefulWidget {
  const ReservasPage({super.key, required this.usuario});

  final AppUser usuario;

  @override
  ConsumerState<ReservasPage> createState() => _ReservasPageState();
}

class _ReservasPageState extends ConsumerState<ReservasPage> {
  var _grupo = GrupoReserva.pendientes;

  @override
  Widget build(BuildContext context) {
    final reservas = ref.watch(reservasDelHuespedProvider(widget.usuario.id));
    final hoy = ref.watch(relojProvider)();
    return Scaffold(
      appBar: AppBar(title: const Text('Mis reservas')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
            child: SegmentedButton<GrupoReserva>(
              segments: const [
                ButtonSegment(
                  value: GrupoReserva.pendientes,
                  label: Text('Pendientes'),
                ),
                ButtonSegment(
                  value: GrupoReserva.proximas,
                  label: Text('Próximas'),
                ),
                ButtonSegment(
                  value: GrupoReserva.anteriores,
                  label: Text('Anteriores'),
                ),
              ],
              selected: {_grupo},
              showSelectedIcon: false,
              onSelectionChanged: (s) => setState(() => _grupo = s.single),
            ),
          ),
          Expanded(
            child: reservas.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, _) => _Mensaje(
                icono: Icons.cloud_off_outlined,
                titulo: 'No pudimos leer tus reservas',
                detalle: 'Inténtalo de nuevo.',
                accion: FilledButton.tonalIcon(
                  onPressed: () => ref.invalidate(
                    reservasDelHuespedProvider(widget.usuario.id),
                  ),
                  icon: const Icon(Icons.refresh),
                  label: const Text('Reintentar'),
                ),
              ),
              data: (todas) {
                final delGrupo = todas
                    .where((r) => r.grupo(hoy) == _grupo)
                    .toList();
                if (delGrupo.isEmpty) return _vacio();
                return ListView(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                  children: [
                    for (final r in delGrupo) _ReservaTile(reserva: r),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _vacio() => switch (_grupo) {
    GrupoReserva.pendientes => const _Mensaje(
      icono: Icons.hourglass_empty,
      titulo: 'No tienes solicitudes pendientes',
      detalle: 'Explora alojamientos y solicita una estadía.',
    ),
    GrupoReserva.proximas => const _Mensaje(
      icono: Icons.event_available_outlined,
      titulo: 'No tienes estadías próximas',
      detalle: 'Cuando pagues una reserva aceptada aparecerá aquí.',
    ),
    GrupoReserva.anteriores => const _Mensaje(
      icono: Icons.history,
      titulo: 'Aún no hay estadías anteriores',
      detalle: 'Aquí verás las terminadas, canceladas o rechazadas.',
    ),
  };
}

class _ReservaTile extends StatelessWidget {
  const _ReservaTile({required this.reserva});

  final Reserva reserva;

  @override
  Widget build(BuildContext context) {
    final r = reserva;
    final noches = r.noches == 1 ? '1 noche' : '${r.noches} noches';
    return Card(
      elevation: 0,
      color: AppColors.surface,
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(color: AppColors.line),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => Navigator.of(context).push<void>(
          MaterialPageRoute<void>(
            builder: (_) => ReservaDetallePage(reservaId: r.id),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(r.titulo, style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 4),
              Text(
                '${rangoFechas(r.entrada, r.salida)} · $noches · '
                '${r.huespedes} huésp.',
                style: const TextStyle(color: AppColors.muted),
              ),
              const SizedBox(height: 10),
              EstadoReservaChip(estado: r.estado),
            ],
          ),
        ),
      ),
    );
  }
}

class _Mensaje extends StatelessWidget {
  const _Mensaje({
    required this.icono,
    required this.titulo,
    required this.detalle,
    this.accion,
  });

  final IconData icono;
  final String titulo;
  final String detalle;
  final Widget? accion;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icono, size: 34, color: AppColors.blue),
          const SizedBox(height: 12),
          Text(
            titulo,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 6),
          Text(
            detalle,
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.muted, height: 1.4),
          ),
          if (accion != null) ...[const SizedBox(height: 16), accion!],
        ],
      ),
    ),
  );
}
