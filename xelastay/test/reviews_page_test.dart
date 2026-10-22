import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xelastay/features/stays/data/repositories/reviews_repository.dart';
import 'package:xelastay/features/stays/presentation/pages/reviews_page.dart';

class FakeErrorReviewsRepository implements IReviewsRepository {
  @override
  Future<List<ReviewItem>> fetchReviews({
    bool forceError = false,
    bool forceEmpty = false,
  }) async {
    throw Exception('Error al cargar reseñas');
  }
}

void main() {
  testWidgets('Muestra mensaje de error y boton Reintentar en reseñas', (
    tester,
  ) async {
    final fakeRepo = FakeErrorReviewsRepository();

    await tester.pumpWidget(
      MaterialApp(home: ReviewsPage(repository: fakeRepo)),
    );

    await tester.pump();

    expect(find.text('No pudimos cargar los datos.'), findsOneWidget);
    expect(find.widgetWithText(ElevatedButton, 'Reintentar'), findsOneWidget);
  });
}
