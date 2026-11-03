import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xelastay/core/theme/app_theme.dart';
import 'package:xelastay/features/auth/domain/entities/app_user.dart';
import 'package:xelastay/features/resenas/presentation/providers/resenas_providers.dart';
import 'package:xelastay/features/stays/domain/entities/stay.dart';
import 'package:xelastay/features/stays/presentation/pages/mapa_alojamientos_page.dart';
import 'package:xelastay/features/stays/presentation/pages/stay_detail_page.dart';

import '../resenas/resenas_en_memoria.dart';

void main() {
  testWidgets('un pin por alojamiento; al tocarlo se ve su tarjeta', (
    tester,
  ) async {
    await _abrir(tester, const [_centro, _cabana]);

    expect(find.byKey(const ValueKey('pin-centro')), findsOneWidget);
    expect(find.byKey(const ValueKey('pin-cabana')), findsOneWidget);
    expect(find.text('Q 250'), findsOneWidget);
    expect(find.text('Ver detalle'), findsNothing);

    await tester.tap(find.byKey(const ValueKey('pin-cabana')));
    await tester.pumpAndSettle();
    expect(find.text('Cabaña con vista a las montañas'), findsOneWidget);
    expect(
      find.text('Ubicación pendiente de revisión: el pin es aproximado.'),
      findsOneWidget,
    );

    await tester.tap(find.text('Ver detalle'));
    await tester.pumpAndSettle();
    expect(find.byType(StayDetailPage), findsOneWidget);
  });

  testWidgets('avisa cuáles no tienen ubicación en vez de inventarla', (
    tester,
  ) async {
    await _abrir(tester, const [_centro, _sinUbicacion]);

    expect(find.byKey(const ValueKey('pin-centro')), findsOneWidget);
    expect(find.byKey(const ValueKey('pin-sin')), findsNothing);
    expect(
      find.text('1 alojamiento no tiene ubicación y solo sale en la lista.'),
      findsOneWidget,
    );
  });
}

Future<void> _abrir(WidgetTester tester, List<Stay> stays) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    ProviderScope(
      // "Ver detalle" abre el alojamiento; sus reseñas vienen de memoria.
      overrides: [
        resenasRepositoryProvider.overrideWithValue(ResenasEnMemoria()),
      ],
      child: MaterialApp(
        theme: buildAppTheme(),
        home: MapaAlojamientosPage(
          stays: stays,
          usuario: const AppUser(
            id: 'ana',
            name: 'Ana López',
            email: 'ana@example.com',
            role: AppRole.guest,
          ),
          // Sin teselas: la prueba no descarga el mapa de internet.
          capaDeMapa: const SizedBox.shrink(),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

const _centro = Stay(
  id: 'centro',
  title: 'Apartamento en el centro de Xela',
  propertyType: 'Apartamento',
  capacity: 2,
  priceAmount: 25000,
  currency: 'GTQ',
  ratingAverage: 0,
  ratingCount: 0,
  zone: 'Zona 1',
  reference: 'Cerca del Parque Central',
  verificationStatus: 'verified',
  latitud: 14.8347,
  longitud: -91.5180,
);

const _cabana = Stay(
  id: 'cabana',
  title: 'Cabaña con vista a las montañas',
  propertyType: 'Cabaña',
  capacity: 4,
  priceAmount: 45000,
  currency: 'GTQ',
  ratingAverage: 0,
  ratingCount: 0,
  zone: 'Las afueras de Xela',
  reference: 'Camino a las montañas',
  verificationStatus: 'pending',
  latitud: 14.8300,
  longitud: -91.5120,
);

const _sinUbicacion = Stay(
  id: 'sin',
  title: 'Cuarto sin coordenadas',
  propertyType: 'Cuarto',
  capacity: 1,
  priceAmount: 15000,
  currency: 'GTQ',
  ratingAverage: 0,
  ratingCount: 0,
  zone: 'Zona 3',
  reference: '',
  verificationStatus: 'pending',
);
