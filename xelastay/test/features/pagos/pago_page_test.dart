import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xelastay/core/theme/app_theme.dart';
import 'package:xelastay/features/booking/domain/entities/reserva.dart';
import 'package:xelastay/features/booking/presentation/pages/reserva_detalle_page.dart';
import 'package:xelastay/features/booking/presentation/providers/reservas_providers.dart';
import 'package:xelastay/features/pagos/domain/entities/pago.dart';
import 'package:xelastay/features/pagos/domain/repositories/pagos_repository.dart';
import 'package:xelastay/features/pagos/presentation/providers/pagos_providers.dart';

void main() {
  testWidgets('una reserva aceptada se paga eligiendo el método', (
    tester,
  ) async {
    final pagos = _Pagos();
    await _abrirDetalle(tester, EstadoReserva.aceptada, pagos);

    await tester.tap(find.text('Pagar y confirmar'));
    await tester.pumpAndSettle();

    expect(find.text('Q 550.00'), findsOneWidget); // total del desglose
    final pagar = find.widgetWithText(
      FilledButton,
      'Pagar Q 550.00',
      skipOffstage: false,
    );
    // Sin método elegido no se puede pagar.
    expect(tester.widget<FilledButton>(pagar).onPressed, isNull);

    await tester.tap(find.text('Transferencia bancaria'));
    await tester.pump();
    await tester.ensureVisible(pagar);
    await tester.pumpAndSettle(); // que el scroll termine antes de tocar
    await tester.tap(pagar);
    await tester.pumpAndSettle();

    expect(pagos.pagados, [(7, MetodoPago.transferencia)]);
    expect(
      find.text('Pago registrado. Tu estadía está confirmada.'),
      findsOneWidget,
    );
  });

  testWidgets('si ya estaba pagada, explica y no cierra', (tester) async {
    final pagos = _Pagos()..yaPagada = true;
    await _abrirDetalle(tester, EstadoReserva.aceptada, pagos);

    await tester.tap(find.text('Pagar y confirmar'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Efectivo al llegar'));
    await tester.pump();
    final pagar = find.widgetWithText(
      FilledButton,
      'Pagar Q 550.00',
      skipOffstage: false,
    );
    await tester.ensureVisible(pagar);
    await tester.pumpAndSettle(); // que el scroll termine antes de tocar
    await tester.tap(pagar);
    await tester.pumpAndSettle();

    expect(find.text('Esta reserva ya está pagada.'), findsOneWidget);
    expect(find.text('Pagar reserva'), findsOneWidget); // sigue en la pantalla
  });

  testWidgets('una reserva confirmada muestra su comprobante', (tester) async {
    final pagos = _Pagos()
      ..comprobante = Pago(
        id: 1,
        reservaId: 7,
        metodo: MetodoPago.transferencia,
        subtotalCentavos: 50000,
        servicioCentavos: 5000,
        totalCentavos: 55000,
        referencia: 'XS-00007',
        pagadoEn: DateTime(2026, 11, 10, 18, 5),
      );
    await _abrirDetalle(tester, EstadoReserva.confirmada, pagos);

    expect(find.text('Pagar y confirmar'), findsNothing);
    expect(find.text('Comprobante XS-00007'), findsOneWidget);
    expect(find.text('Pagado con Transferencia bancaria'), findsOneWidget);
  });
}

Future<void> _abrirDetalle(
  WidgetTester tester,
  EstadoReserva estado,
  _Pagos pagos,
) async {
  tester.view.physicalSize = const Size(390, 1400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final reserva = Reserva(
    id: 7,
    stayId: 'centro',
    titulo: 'Apartamento en el centro de Xela',
    zona: 'Zona 1',
    precioNocheCentavos: 25000,
    entrada: DateTime(2026, 11, 14),
    salida: DateTime(2026, 11, 16),
    huespedes: 2,
    huespedId: 'ana',
    huespedNombre: 'Ana López',
    estado: estado,
    creadaEn: DateTime(2026, 11, 2),
  );
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        // La reserva viene fija; el pago usa un repositorio en memoria.
        reservaPorIdProvider.overrideWith((ref, id) async => reserva),
        pagosRepositoryProvider.overrideWithValue(pagos),
      ],
      child: MaterialApp(
        theme: buildAppTheme(),
        home: const ReservaDetallePage(reservaId: 7),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

class _Pagos implements PagosRepository {
  final pagados = <(int, MetodoPago)>[];
  bool yaPagada = false;
  Pago? comprobante;

  @override
  Future<Pago> pagar(int reservaId, MetodoPago metodo) async {
    if (yaPagada) throw const PagoException('Esta reserva ya está pagada.');
    pagados.add((reservaId, metodo));
    return Pago(
      id: 1,
      reservaId: reservaId,
      metodo: metodo,
      subtotalCentavos: 50000,
      servicioCentavos: 5000,
      totalCentavos: 55000,
      referencia: 'XS-00007',
      pagadoEn: DateTime(2026, 11, 10),
    );
  }

  @override
  Future<Pago?> deReserva(int reservaId) async => comprobante;
}
