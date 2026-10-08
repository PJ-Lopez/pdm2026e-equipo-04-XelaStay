class Stay {
  const Stay({
    required this.id,
    required this.title,
    required this.propertyType,
    required this.capacity,
    required this.priceAmount,
    required this.currency,
    required this.ratingAverage,
    required this.ratingCount,
    required this.zone,
    required this.reference,
    required this.verificationStatus,
    this.coverPhotoUrl,
    this.isFavorite = false,
  });

  final String id;
  final String title;
  final String propertyType;
  final int capacity;
  final int priceAmount;
  final String currency;
  final double ratingAverage;
  final int ratingCount;
  final String zone;
  final String reference;
  final String verificationStatus;
  final String? coverPhotoUrl;
  final bool isFavorite;

  double get priceInCurrency => priceAmount / 100;
  bool get isVerified => verificationStatus == 'verified';
}
