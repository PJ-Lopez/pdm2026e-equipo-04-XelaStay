class SavedStay {
  final String id;
  final String title;
  final String locationTag;
  final String distanceText;
  final double pricePerNight;
  final double rating;
  final int reviewCount;
  final String imageUrl;
  final String? featureBadge;
  final bool isVerified;
  final bool isFavorite;

  const SavedStay({
    required this.id,
    required this.title,
    required this.locationTag,
    required this.distanceText,
    required this.pricePerNight,
    required this.rating,
    required this.reviewCount,
    required this.imageUrl,
    this.featureBadge,
    this.isVerified = true,
    this.isFavorite = true,
  });
}
