import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xelastay/core/theme/app_theme.dart';
import 'package:xelastay/features/auth/domain/entities/app_user.dart';
import 'package:xelastay/features/booking/domain/entities/reserva.dart';
import 'package:xelastay/features/booking/presentation/pages/reserva_detalle_page.dart';
import 'package:xelastay/features/booking/presentation/providers/reservas_providers.dart';
import 'package:xelastay/features/pagos/domain/entities/pago.dart';
import 'package:xelastay/features/pagos/domain/repositories/pagos_repository.dart';
import 'package:xelastay/features/pagos/presentation/providers/pagos_providers.dart';
import 'package:xelastay/features/resenas/domain/entities/resena.dart';
import 'package:xelastay/features/resenas/presentation/providers/resenas_providers.dart';
import 'package:xelastay/features/stays/domain/entities/stay.dart';
import 'package:xelastay/features/stays/presentation/pages/stay_detail_page.dart';

import 'resenas_en_memoria.dart';

void main() {
  testWidgets('después de la estadía se reseña desde el detalle', (
    tester,
  ) async {
    final resenas = ResenasEnMemoria();
    await _abrirReserva(tester, resenas);

    await tester.tap(find.text('Escribir reseña'));
    await tester.pumpAndSettle();

    final publicar = find.widgetWithText(FilledButton, 'Publicar reseña');
    // Sin estrellas no se puede publicar.
    expect(tester.widget<FilledButton>(publicar).onPressed, isNull);

    await tester.tap(find.byTooltip('4 estrellas'));
    await tester.pump();
    expect(find.text('4 de 5 · Muy buena'), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'Muy limpio.');
    await tester.tap(publicar);
    await tester.pumpAndSettle();

    expect(resenas.datos.single.estrellas, 4);
    expect(
      find.text('Gracias. Tu reseña ya aparece en el alojamiento.'),
      findsOneWidget,
    );
    // El detalle volvió a leer: ya no ofrece reseñar otra vez.
    expect(find.text('Escribir reseña'), findsNothing);
    expect(find.text('Tu reseña'), findsOneWidget);
    expect(find.text('Muy limpio.'), findsOneWidget);
  });

  testWidgets('si la regla no deja, explica y no cierra', (tester) async {
    final resenas = ResenasEnMemoria()
      ..reglaQueFalla = 'Ya reseñaste esta estadía.';
    await _abrirReserva(tester, resenas);

    await tester.tap(find.text('Escribir reseña'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('5 estrellas'));
    await tester.pump();
    await tester.tap(find.widgetWithText(FilledButton, 'Publicar reseña'));
    await tester.pumpAndSettle();

    expect(find.text('Ya reseñaste esta estadía.'), findsOneWidget);
    expect(find.text('Reseñar estadía'), findsOneWidget); // sigue abierta
  });

  testWidgets('el alojamiento suma la reseña y la marca como verificada', (
    tester,
  ) async {
    final resenas = ResenasEnMemoria([
      Resena(
        id: 1,
        reservaId: 7,
        stayId: 'centro',
        autor: 'Ana López',
        estrellas: 5,
        comentario: 'Excelente ubicación.',
        creadaEn: DateTime(2026, 11, 17),
      ),
    ]);
    await _abrirAlojamiento(tester, resenas);

    // 12 del catálogo con 4.8 + una de 5 = 4.8 con 13 reseñas.
    expect(find.text('4.8 · 13 reseñas'), findsOneWidget);
    expect(find.text('Reseñas de huéspedes'), findsOneWidget);
    expect(find.text('Excelente ubicación.'), findsOneWidget);
    expect(find.text('Estadía verificada'), findsOneWidget);
  });

  testWidgets('si no se pueden leer las reseñas, ofrece reintentar', (
    tester,
  ) async {
    final resenas = ResenasEnMemoria()..fallarAlLeer = true;
    await _abrirAlojamiento(tester, resenas);

    // Mientras tanto se ve la calificación del catálogo.
    expect(find.text('4.8 · 12 reseñas'), findsOneWidget);
    final reintentar = find.text('No pudimos leer las reseñas. Reintentar');
    expect(reintentar, findsOneWidget);

    resenas.fallarAlLeer = false;
    await tester.tap(reintentar);
    await tester.pumpAndSettle();
    expect(reintentar, findsNothing);
  });
}

void _pantallaDeTelefono(WidgetTester tester) {
  tester.view.physicalSize = const Size(390, 1400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

Future<void> _abrirReserva(
  WidgetTester tester,
  ResenasEnMemoria resenas,
) async {
  _pantallaDeTelefono(tester);
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
    estado: EstadoReserva.completada,
    creadaEn: DateTime(2026, 11, 2),
  );
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        reservaPorIdProvider.overrideWith((ref, id) async => reserva),
        pagosRepositoryProvider.overrideWithValue(_SinPago()),
        resenasRepositoryProvider.overrideWithValue(resenas),
      ],
      child: MaterialApp(
        theme: buildAppTheme(),
        home: const ReservaDetallePage(reservaId: 7),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _abrirAlojamiento(
  WidgetTester tester,
  ResenasEnMemoria resenas,
) async {
  _pantallaDeTelefono(tester);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [resenasRepositoryProvider.overrideWithValue(resenas)],
      child: MaterialApp(
        theme: buildAppTheme(),
        home: const StayDetailPage(
          stay: Stay(
            id: 'centro',
            title: 'Apartamento en el centro de Xela',
            propertyType: 'Apartamento',
            capacity: 2,
            priceAmount: 25000,
            currency: 'GTQ',
            ratingAverage: 4.8,
            ratingCount: 12,
            zone: 'Zona 1',
            reference: 'Cerca del Parque Central',
            verificationStatus: 'verified',
          ),
          usuario: AppUser(
            id: 'ana',
            name: 'Ana López',
            email: 'ana@example.com',
            role: AppRole.guest,
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

/// El comprobante no importa en estas pruebas.
class _SinPago implements PagosRepository {
  @override
  Future<Pago> pagar(int reservaId, MetodoPago metodo) =>
      throw UnimplementedError();

  @override
  Future<Pago?> deReserva(int reservaId) async => null;
}
