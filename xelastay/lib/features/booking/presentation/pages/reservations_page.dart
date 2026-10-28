import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/guest_reservation.dart';
import '../../domain/repositories/reservations_repository.dart';
import '../providers/reservations_providers.dart';

class ReservationsPage extends ConsumerStatefulWidget {
  const ReservationsPage({super.key});

  @override
  ConsumerState<ReservationsPage> createState() => _ReservationsPageState();
}

class _ReservationsPageState extends ConsumerState<ReservationsPage> {
  final _searchController = TextEditingController();
  final _dismissedIds = <String>{};

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filter = ref.watch(reservationFilterProvider);
    final reservations = ref.watch(reservationsProvider);
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _header(),
            _searchField(filter.query),
            _tabs(reservations.asData?.value.counts ?? const {}),
            Expanded(
              child: reservations.when(
                loading: () => const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 12),
                      Text('Cargando reservas'),
                    ],
                  ),
                ),
                error: (_, _) => _ErrorState(
                  onRetry: () => ref.invalidate(reservationsProvider),
                ),
                data: _reservationList,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _reservationList(ReservationListResult result) {
    final filter = ref.read(reservationFilterProvider);
    final visible = result.items
        .where((reservation) => !_dismissedIds.contains(reservation.id))
        .toList();
    if (visible.isEmpty) return _emptyState(filter);
    return ListView.separated(
      key: const ValueKey('reservations-list'),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
      itemCount: visible.length,
      separatorBuilder: (_, _) => const SizedBox(height: 16),
      itemBuilder: (context, index) {
        final reservation = visible[index];
        return Dismissible(
          key: ValueKey(reservation.id),
          direction: DismissDirection.endToStart,
          background: Container(
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 24),
            decoration: BoxDecoration(
              color: AppColors.red,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(Icons.delete_outline, color: Colors.white),
          ),
          onDismissed: (_) => _deleteReservation(reservation),
          child: _ReservationCard(
            reservation: reservation,
            onTap: () => Navigator.of(context).push<void>(
              MaterialPageRoute<void>(
                builder: (_) => ReservationDetailPage(reservation: reservation),
              ),
            ),
          ),
        );
      },
    );
  }

  void _deleteReservation(GuestReservation reservation) {
    setState(() => _dismissedIds.add(reservation.id));
    unawaited(_deleteAndOfferUndo(reservation));
  }

  Future<void> _deleteAndOfferUndo(GuestReservation reservation) async {
    try {
      await ref
          .read(reservationsRepositoryProvider)
          .deleteReservation(reservation.id);
      if (!mounted) return;
      ref.invalidate(reservationsProvider);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Reserva eliminada'),
          action: SnackBarAction(
            label: 'Deshacer',
            onPressed: () => unawaited(_restoreReservation(reservation)),
          ),
        ),
      );
    } catch (_) {
      // Give Dismissible a frame to leave the sliver before reintroducing its key.
      await WidgetsBinding.instance.endOfFrame;
      if (!mounted) return;
      setState(() => _dismissedIds.remove(reservation.id));
      ref.invalidate(reservationsProvider);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se pudo eliminar. La reserva sigue en tu lista.'),
        ),
      );
    }
  }

  Future<void> _restoreReservation(GuestReservation reservation) async {
    try {
      await ref
          .read(reservationsRepositoryProvider)
          .restoreReservation(reservation);
      if (!mounted) return;
      setState(() => _dismissedIds.remove(reservation.id));
      ref.invalidate(reservationsProvider);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo restaurar la reserva.')),
      );
    }
  }

  Widget _header() => Padding(
    padding: const EdgeInsets.fromLTRB(20, 8, 12, 4),
    child: Row(
      children: [
        const Icon(Icons.travel_explore, color: AppColors.blue, size: 23),
        const SizedBox(width: 9),
        Expanded(
          child: Text(
            'Tus Reservas',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontSize: 21),
          ),
        ),
        IconButton(
          tooltip: 'Filtros',
          onPressed: _showFilters,
          icon: const Icon(Icons.tune_rounded),
        ),
      ],
    ),
  );

  Widget _searchField(String query) {
    if (_searchController.text != query) _searchController.text = query;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 3, 16, 5),
      child: TextField(
        key: const ValueKey('reservation-search'),
        controller: _searchController,
        onChanged: ref.read(reservationFilterProvider.notifier).updateQuery,
        decoration: InputDecoration(
          hintText: 'Buscar alojamiento o zona',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: query.isEmpty
              ? null
              : IconButton(
                  tooltip: 'Limpiar búsqueda',
                  onPressed: () {
                    _searchController.clear();
                    ref
                        .read(reservationFilterProvider.notifier)
                        .updateQuery('');
                  },
                  icon: const Icon(Icons.close),
                ),
        ),
      ),
    );
  }

  Widget _tabs(Map<ReservationGroup, int> counts) {
    const groups = ReservationGroup.values;
    const labels = ['Pendientes', 'Próximas', 'Anteriores'];
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 5, 16, 8),
      child: Row(
        children: [
          for (var index = 0; index < groups.length; index++) ...[
            if (index > 0) const SizedBox(width: 7),
            Expanded(
              child: _ReservationTab(
                label: labels[index],
                count: counts[groups[index]] ?? 0,
                selected:
                    groups[index] == ref.watch(reservationFilterProvider).group,
                onTap: () => ref
                    .read(reservationFilterProvider.notifier)
                    .selectGroup(groups[index]),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _emptyState(ReservationFilter filter) => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.luggage_outlined, size: 44, color: AppColors.muted),
          const SizedBox(height: 12),
          Text(
            filter.query.isNotEmpty
                ? 'No hay reservas que coincidan con “${filter.query}”'
                : 'Aún no tienes reservas en ${_groupLabel(filter.group).toLowerCase()}',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 6),
          const Text(
            'Prueba otro filtro o revisa esta sección más tarde.',
            textAlign: TextAlign.center,
          ),
        ],
      ),
    ),
  );

  void _showFilters() => showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (context) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Filtrar reservas',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            const Text(
              'Selecciona una sección para ver tus solicitudes y estadías.',
            ),
            const SizedBox(height: 16),
            for (final group in ReservationGroup.values)
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(_groupLabel(group)),
                trailing: group == ref.read(reservationFilterProvider).group
                    ? const Icon(Icons.check, color: AppColors.blue)
                    : null,
                onTap: () {
                  ref
                      .read(reservationFilterProvider.notifier)
                      .selectGroup(group);
                  Navigator.pop(context);
                },
              ),
          ],
        ),
      ),
    ),
  );
}

String _groupLabel(ReservationGroup group) => switch (group) {
  ReservationGroup.pending => 'Pendientes',
  ReservationGroup.upcoming => 'Próximas',
  ReservationGroup.past => 'Anteriores',
};

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.cloud_off_outlined,
            size: 42,
            color: AppColors.muted,
          ),
          const SizedBox(height: 12),
          Text(
            'No pudimos cargar tus reservas',
            style: Theme.of(context).textTheme.titleMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          const Text(
            'Revisa tu conexión e inténtalo de nuevo.',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          FilledButton.tonalIcon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: const Text('Reintentar'),
          ),
        ],
      ),
    ),
  );
}

class _ReservationTab extends StatelessWidget {
  const _ReservationTab({
    required this.label,
    required this.count,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final int count;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: selected ? AppColors.blueSoft : AppColors.surface,
    borderRadius: BorderRadius.circular(24),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: selected ? AppColors.blue : AppColors.line,
            width: selected ? 1.4 : 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11,
                  color: selected ? AppColors.blue : AppColors.muted,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ),
            const SizedBox(width: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
              decoration: BoxDecoration(
                color: selected ? AppColors.blue : AppColors.canvas,
                shape: BoxShape.circle,
              ),
              child: Text(
                '$count',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: selected ? Colors.white : AppColors.muted,
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _ReservationCard extends StatelessWidget {
  const _ReservationCard({required this.reservation, required this.onTap});

  final GuestReservation reservation;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: AppColors.surface,
    borderRadius: BorderRadius.circular(20),
    clipBehavior: Clip.antiAlias,
    child: InkWell(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _StayCover(reservation: reservation),
          _statusNotice(reservation),
          _progress(reservation),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
            child: Row(
              children: [
                Expanded(
                  child: _InfoTile(
                    icon: Icons.calendar_month_outlined,
                    label: 'Fechas',
                    value:
                        '${reservation.checkIn.day} – ${reservation.checkOut.day}\n${_monthName(reservation.checkIn.month)}',
                    detail: '${reservation.nights} noches reservadas',
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _InfoTile(
                    icon: Icons.people_outline,
                    label: 'Huéspedes',
                    value:
                        '${reservation.guestCount} ${reservation.guestCount == 1 ? 'adulto' : 'adultos'}',
                    detail: 'Cabaña completa',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );

  Widget _statusNotice(GuestReservation reservation) {
    final confirmed = reservation.status == 'confirmed';
    final background = confirmed
        ? const Color(0xFFEAF5EF)
        : const Color(0xFFFFF7E5);
    final foreground = confirmed ? AppColors.success : const Color(0xFF95651B);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 11, 14, 12),
      color: background,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            confirmed
                ? Icons.check_circle_outline
                : Icons.hourglass_bottom_rounded,
            size: 19,
            color: foreground,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  reservation.statusMessage,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: foreground,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  reservation.statusDetail,
                  style: TextStyle(
                    fontSize: 11,
                    height: 1.35,
                    color: foreground,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _progress(GuestReservation reservation) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 13, 16, 3),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'PROGRESO DE LA SOLICITUD',
          style: TextStyle(
            fontSize: 10,
            letterSpacing: .8,
            color: AppColors.muted,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 11),
        _ProgressStep(
          title: 'Solicitud enviada',
          detail: reservation.createdLabel,
          state: _StepState.done,
          last: false,
        ),
        _ProgressStep(
          title: reservation.status == 'confirmed'
              ? 'Reserva confirmada'
              : 'Esperando respuesta del anfitrión',
          detail: reservation.responseDeadline,
          state: reservation.status == 'confirmed'
              ? _StepState.done
              : _StepState.current,
          last: false,
        ),
        _ProgressStep(
          title: 'Confirmación y detalles de llegada',
          detail: reservation.status == 'confirmed'
              ? 'Código de acceso e instrucciones disponibles'
              : 'Código de acceso autónomo e instrucciones de ruta',
          state: reservation.status == 'confirmed'
              ? _StepState.done
              : _StepState.upcoming,
          last: true,
        ),
      ],
    ),
  );
}

class _StayCover extends StatelessWidget {
  const _StayCover({required this.reservation});
  final GuestReservation reservation;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 160,
    width: double.infinity,
    child: Stack(
      fit: StackFit.expand,
      children: [
        const _CabinIllustration(),
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withValues(alpha: .05),
                Colors.black.withValues(alpha: .65),
              ],
              stops: const [.2, 1],
            ),
          ),
        ),
        Positioned(
          top: 12,
          left: 12,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: .94),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  reservation.verified
                      ? Icons.verified_rounded
                      : Icons.location_on_outlined,
                  size: 14,
                  color: reservation.verified
                      ? AppColors.blue
                      : AppColors.muted,
                ),
                const SizedBox(width: 5),
                Text(
                  reservation.verified
                      ? 'Estadía verificada'
                      : 'Verificación pendiente',
                  style: const TextStyle(
                    fontSize: 10,
                    color: AppColors.ink,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
        Positioned(
          left: 13,
          right: 12,
          bottom: 11,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.place, size: 13, color: Colors.white),
                  const SizedBox(width: 3),
                  Expanded(
                    child: Text(
                      reservation.location,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 3),
              Text(
                reservation.stayName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _CabinIllustration extends StatelessWidget {
  const _CabinIllustration();

  @override
  Widget build(BuildContext context) => const DecoratedBox(
    decoration: BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color(0xFF8CAEB4),
          Color(0xFFCCD9CF),
          Color(0xFF355545),
          Color(0xFF19372E),
        ],
      ),
    ),
    child: Stack(
      children: [
        Positioned(
          top: 25,
          left: 32,
          child: Icon(Icons.cloud, size: 66, color: Color(0x77FFFFFF)),
        ),
        Positioned(
          top: 52,
          right: 28,
          child: Icon(Icons.landscape, size: 130, color: Color(0x663D6264)),
        ),
        Positioned(
          bottom: 8,
          left: 12,
          child: Icon(Icons.park, size: 95, color: Color(0xCC173C2B)),
        ),
        Positioned(
          bottom: 15,
          right: 12,
          child: Icon(Icons.park, size: 112, color: Color(0xDD214833)),
        ),
        Positioned(
          bottom: 21,
          left: 0,
          right: 0,
          child: Icon(Icons.cabin, size: 92, color: Color(0xFFE5B978)),
        ),
      ],
    ),
  );
}

enum _StepState { done, current, upcoming }

class _ProgressStep extends StatelessWidget {
  const _ProgressStep({
    required this.title,
    required this.detail,
    required this.state,
    required this.last,
  });
  final String title;
  final String detail;
  final _StepState state;
  final bool last;

  @override
  Widget build(BuildContext context) {
    final color = switch (state) {
      _StepState.done => AppColors.success,
      _StepState.current => const Color(0xFFB48B4B),
      _StepState.upcoming => const Color(0xFFD5DAE0),
    };
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 20,
            child: Column(
              children: [
                Container(
                  width: 18,
                  height: 18,
                  decoration: BoxDecoration(
                    color: state == _StepState.done ? color : AppColors.surface,
                    shape: BoxShape.circle,
                    border: Border.all(color: color, width: 2),
                  ),
                  child: state == _StepState.done
                      ? const Icon(Icons.check, size: 12, color: Colors.white)
                      : null,
                ),
                if (!last)
                  Expanded(
                    child: Container(
                      width: 1.5,
                      color: const Color(0xFFE3E7EB),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 11),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: state == _StepState.upcoming
                          ? AppColors.muted
                          : AppColors.ink,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    detail,
                    style: const TextStyle(
                      fontSize: 11,
                      height: 1.3,
                      color: AppColors.muted,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.detail,
  });
  final IconData icon;
  final String label;
  final String value;
  final String detail;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(11),
    decoration: BoxDecoration(
      color: AppColors.surface,
      border: Border.all(color: AppColors.line),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 14, color: AppColors.muted),
            const SizedBox(width: 5),
            Text(
              label,
              style: const TextStyle(
                fontSize: 10,
                color: AppColors.muted,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 5),
        Text(
          value,
          style: const TextStyle(
            fontSize: 13,
            color: AppColors.ink,
            fontWeight: FontWeight.w700,
            height: 1.2,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          detail,
          style: const TextStyle(fontSize: 10, color: AppColors.muted),
        ),
      ],
    ),
  );
}

class ReservationDetailPage extends StatelessWidget {
  const ReservationDetailPage({super.key, required this.reservation});
  final GuestReservation reservation;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Detalle de reserva')),
    body: ListView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 28),
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: SizedBox(height: 190, child: _CabinIllustration()),
        ),
        const SizedBox(height: 16),
        Text(
          reservation.stayName,
          style: Theme.of(
            context,
          ).textTheme.headlineMedium?.copyWith(fontSize: 23),
        ),
        const SizedBox(height: 5),
        Row(
          children: [
            const Icon(Icons.place_outlined, size: 16, color: AppColors.muted),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                reservation.location,
                style: const TextStyle(color: AppColors.muted),
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: reservation.status == 'confirmed'
                ? const Color(0xFFEAF5EF)
                : const Color(0xFFFFF7E5),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                reservation.statusMessage,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  color: AppColors.ink,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                reservation.statusDetail,
                style: const TextStyle(color: AppColors.muted, height: 1.4),
              ),
              const SizedBox(height: 10),
              Text(
                reservation.responseDeadline,
                style: const TextStyle(
                  color: AppColors.blue,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        Text(
          'Progreso de la solicitud',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 12),
        _ProgressStep(
          title: 'Solicitud enviada',
          detail: reservation.createdLabel,
          state: _StepState.done,
          last: false,
        ),
        _ProgressStep(
          title: reservation.status == 'confirmed'
              ? 'Reserva confirmada'
              : 'Esperando respuesta del anfitrión',
          detail: reservation.responseDeadline,
          state: reservation.status == 'confirmed'
              ? _StepState.done
              : _StepState.current,
          last: false,
        ),
        _ProgressStep(
          title: 'Confirmación y detalles de llegada',
          detail: reservation.status == 'confirmed'
              ? 'Código de acceso autónomo e instrucciones de ruta'
              : 'Disponible al confirmar la estadía',
          state: reservation.status == 'confirmed'
              ? _StepState.done
              : _StepState.upcoming,
          last: true,
        ),
        const SizedBox(height: 12),
        _DetailRow(
          label: 'Fechas',
          value:
              '${reservation.checkIn.day} ${_monthName(reservation.checkIn.month)} – ${reservation.checkOut.day} ${_monthName(reservation.checkOut.month)} (${reservation.nights} noches)',
        ),
        _DetailRow(
          label: 'Huéspedes',
          value:
              '${reservation.guestCount} ${reservation.guestCount == 1 ? 'adulto' : 'adultos'} · Cabaña completa',
        ),
        if (reservation.status == 'confirmed') ...[
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.blueSoft,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Detalles de llegada',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: AppColors.ink,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Código de acceso: XELA-4821',
                  style: TextStyle(color: AppColors.ink),
                ),
                Text(
                  'Llegada autónoma desde las 15:00 hrs',
                  style: TextStyle(color: AppColors.muted),
                ),
                Text(
                  'Las instrucciones completas estarán disponibles antes de tu llegada.',
                  style: TextStyle(color: AppColors.muted),
                ),
              ],
            ),
          ),
        ],
      ],
    ),
  );
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 10),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 92,
          child: Text(label, style: const TextStyle(color: AppColors.muted)),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              color: AppColors.ink,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    ),
  );
}

String _monthName(int month) => const [
  '',
  'Enero',
  'Febrero',
  'Marzo',
  'Abril',
  'Mayo',
  'Junio',
  'Julio',
  'Agosto',
  'Septiembre',
  'Octubre',
  'Noviembre',
  'Diciembre',
][month];
