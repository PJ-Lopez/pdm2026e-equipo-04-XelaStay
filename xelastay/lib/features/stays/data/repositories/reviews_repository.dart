class ReviewItem {
  final String author;
  final String comment;
  final double rating;

  const ReviewItem({
    required this.author,
    required this.comment,
    required this.rating,
  });
}

abstract class IReviewsRepository {
  Future<List<ReviewItem>> fetchReviews({
    bool forceError = false,
    bool forceEmpty = false,
  });
}

class ReviewsRepository implements IReviewsRepository {
  @override
  Future<List<ReviewItem>> fetchReviews({
    bool forceError = false,
    bool forceEmpty = false,
  }) async {
    await Future.delayed(const Duration(milliseconds: 600));

    if (forceError) {
      throw Exception('Error al conectar con el servicio de reseñas');
    }
    if (forceEmpty) {
      return [];
    }

    return const [
      ReviewItem(
        author: 'Carlos G.',
        comment: 'Excelente ubicación cerca del parque central.',
        rating: 5.0,
      ),
      ReviewItem(
        author: 'Sofía M.',
        comment: 'Muy limpio y vecindario seguro en Zona 3.',
        rating: 4.8,
      ),
    ];
  }
}
