import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xelastay/features/booking/domain/entities/guest_reservation.dart';
import 'package:xelastay/features/booking/domain/repositories/reservations_repository.dart';
import 'package:xelastay/features/booking/presentation/pages/reservations_page.dart';
import 'package:xelastay/features/booking/presentation/providers/reservations_providers.dart';

void main() {
  testWidgets('Cambiar pestaña actualiza el filtro y vuelve a consultar', (
    tester,
  ) async {
    final repository = _MemoryReservationsRepository(_sampleReservations);
    await _pumpPage(tester, repository);
    await tester.pumpAndSettle();

    expect(find.text('Cabaña Mirador Santa María'), findsOneWidget);
    expect(repository.queries.last.group, ReservationGroup.pending);

    await tester.tap(find.text('Próximas'));
    await tester.pumpAndSettle();

    expect(repository.queries.last.group, ReservationGroup.upcoming);
    expect(find.text('Casa de Adobe en el Centro'), findsOneWidget);
    expect(find.text('Cabaña Mirador Santa María'), findsNothing);
  });

  testWidgets('Deslizar elimina y Deshacer restaura la misma reserva e id', (
    tester,
  ) async {
    final repository = _MemoryReservationsRepository(_sampleReservations);
    final original = repository.items.first;
    await _pumpPage(tester, repository);
    await tester.pumpAndSettle();

    await tester.drag(
      find.byKey(const ValueKey('reservation-pending')),
      const Offset(-500, 0),
    );
    await tester.pumpAndSettle();

    expect(repository.deletedIds, ['reservation-pending']);
    expect(find.text('Cabaña Mirador Santa María'), findsNothing);
    expect(find.text('Deshacer'), findsOneWidget);

    await tester.tap(find.text('Deshacer'));
    await tester.pumpAndSettle();

    expect(repository.restored, same(original));
    expect(repository.restored?.id, 'reservation-pending');
    expect(find.byKey(const ValueKey('reservation-pending')), findsOneWidget);
    expect(find.text('Cabaña Mirador Santa María'), findsOneWidget);
  });

  testWidgets('Si la base falla al borrar, la fila vuelve a la lista', (
    tester,
  ) async {
    final repository = _MemoryReservationsRepository(
      _sampleReservations,
      failNextDelete: true,
    );
    await _pumpPage(tester, repository);
    await tester.pumpAndSettle();

    await tester.drag(
      find.byKey(const ValueKey('reservation-pending')),
      const Offset(-500, 0),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('reservation-pending')), findsOneWidget);
    expect(find.text('Cabaña Mirador Santa María'), findsOneWidget);
    expect(
      find.text('No se pudo eliminar. La reserva sigue en tu lista.'),
      findsOneWidget,
    );
  });

  testWidgets('Muestra error y permite reintentar la consulta', (tester) async {
    final repository = _MemoryReservationsRepository(
      _sampleReservations,
      failNextQuery: true,
    );
    await _pumpPage(tester, repository);
    await tester.pumpAndSettle();

    expect(find.text('No pudimos cargar tus reservas'), findsOneWidget);
    await tester.tap(find.text('Reintentar'));
    await tester.pumpAndSettle();

    expect(find.text('Cabaña Mirador Santa María'), findsOneWidget);
    expect(repository.queries, hasLength(2));
  });

  testWidgets('El estado vacío explica cuándo el filtro no encuentra datos', (
    tester,
  ) async {
    final repository = _MemoryReservationsRepository(_sampleReservations);
    await _pumpPage(tester, repository);
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'ninguna coincidencia');
    await tester.pumpAndSettle();

    expect(
      find.text('No hay reservas que coincidan con “ninguna coincidencia”'),
      findsOneWidget,
    );
  });
}

Future<void> _pumpPage(
  WidgetTester tester,
  ReservationsRepository repository,
) async {
  tester.view.physicalSize = const Size(390, 1200);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [reservationsRepositoryProvider.overrideWithValue(repository)],
      child: const MaterialApp(home: ReservationsPage()),
    ),
  );
}

class _MemoryReservationsRepository implements ReservationsRepository {
  _MemoryReservationsRepository(
    List<GuestReservation> items, {
    this.failNextQuery = false,
    this.failNextDelete = false,
  }) : items = List.of(items);

  final List<GuestReservation> items;
  final queries = <ReservationFilter>[];
  final deletedIds = <String>[];
  bool failNextQuery;
  bool failNextDelete;
  GuestReservation? restored;

  @override
  Future<ReservationListResult> getReservations(
    ReservationFilter filter,
  ) async {
    queries.add(filter);
    if (failNextQuery) {
      failNextQuery = false;
      throw Exception('Error de conexión');
    }
    final query = filter.query.toLowerCase();
    final all = items.where((item) => item.group == filter.group).toList();
    final filtered = all
        .where(
          (item) =>
              query.isEmpty ||
              '${item.stayName} ${item.location}'.toLowerCase().contains(query),
        )
        .toList();
    return ReservationListResult(
      items: filtered,
      counts: {
        for (final group in ReservationGroup.values)
          group: items.where((item) => item.group == group).length,
      },
    );
  }

  @override
  Future<void> deleteReservation(String id) async {
    if (failNextDelete) {
      failNextDelete = false;
      throw Exception('Error de escritura');
    }
    deletedIds.add(id);
    items.removeWhere((item) => item.id == id);
  }

  @override
  Future<void> restoreReservation(GuestReservation reservation) async {
    restored = reservation;
    items.add(reservation);
  }
}

final _sampleReservations = <GuestReservation>[
  GuestReservation(
    id: 'reservation-pending',
    stayName: 'Cabaña Mirador Santa María',
    location: 'Valle de Palajunoj, Quetzaltenango',
    checkIn: DateTime(2026, 11, 14),
    checkOut: DateTime(2026, 11, 17),
    guestCount: 2,
    group: ReservationGroup.pending,
    status: 'awaiting_host',
    statusMessage: 'Tu solicitud está con el anfitrión',
    statusDetail: 'En espera de respuesta.',
    createdLabel: 'Hoy · Solicitud enviada',
    responseDeadline: 'Hasta mañana para responder',
    verified: true,
  ),
  GuestReservation(
    id: 'reservation-upcoming',
    stayName: 'Casa de Adobe en el Centro',
    location: 'Zona 1, Quetzaltenango',
    checkIn: DateTime(2026, 12, 3),
    checkOut: DateTime(2026, 12, 6),
    guestCount: 3,
    group: ReservationGroup.upcoming,
    status: 'confirmed',
    statusMessage: 'Reserva confirmada',
    statusDetail: 'Tu llegada está lista.',
    createdLabel: 'Confirmada por el anfitrión',
    responseDeadline: 'Detalles disponibles',
    verified: true,
  ),
];
