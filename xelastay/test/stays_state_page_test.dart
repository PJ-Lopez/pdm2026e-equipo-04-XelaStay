import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xelastay/features/stays/data/repositories/stays_state_repository.dart';
import 'package:xelastay/features/stays/presentation/pages/stays_state_page.dart';

// Fake repository que fuerza una excepción simulada
class FakeFailingStaysRepository implements IStaysStateRepository {
  @override
  Future<List<StayItem>> fetchStays({
    bool forceError = false,
    bool forceEmpty = false,
  }) async {
    throw Exception('Error simulado de conexión');
  }
}

void main() {
  testWidgets(
    'Debe mostrar mensaje amigable y botón Reintentar cuando falla el repositorio',
    (tester) async {
      final fakeRepo = FakeFailingStaysRepository();

      await tester.pumpWidget(
        MaterialApp(home: StaysStatePage(repository: fakeRepo)),
      );

      // Permite que el Future resuelva y la UI cambie de ConnectionState.waiting al snapshot con error
      await tester.pump();

      // Verificaciones requeridas
      expect(find.text('No pudimos cargar los datos.'), findsOneWidget);
      expect(find.widgetWithText(ElevatedButton, 'Reintentar'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);
    },
  );
}
