import '../../domain/entities/saved_stay.dart';

class SavedStayModel extends SavedStay {
  const SavedStayModel({
    required super.id,
    required super.title,
    required super.locationTag,
    required super.distanceText,
    required super.pricePerNight,
    required super.rating,
    required super.reviewCount,
    required super.imageUrl,
    super.featureBadge,
    super.isVerified,
    super.isFavorite,
  });

  factory SavedStayModel.fromJson(Map<String, dynamic> json) {
    return SavedStayModel(
      id: json['id']?.toString() ?? json['_id']?.toString() ?? '',
      title:
          json['title'] ??
          json['nombre'] ??
          'Cabaña Mirador Santa María - Zona 1',
      locationTag: json['locationTag'] ?? json['ubicacion'] ?? 'Quetzaltenango',
      distanceText:
          json['distanceText'] ??
          json['distancia'] ??
          'A 8 min a pie del Parque Central',
      pricePerNight: (json['pricePerNight'] ?? json['precio'] ?? 340)
          .toDouble(),
      rating: (json['rating'] ?? json['calificacion'] ?? 4.96).toDouble(),
      reviewCount: json['reviewCount'] ?? json['resenas'] ?? 54,
      imageUrl:
          json['imageUrl'] ??
          json['imagen'] ??
          'https://images.unsplash.com/photo-1542314831-068cd1dbfeeb?w=800',
      featureBadge:
          json['featureBadge'] ?? json['etiqueta'] ?? 'Vista al volcán',
      isVerified: json['isVerified'] ?? true,
      isFavorite: json['isFavorite'] ?? true,
    );
  }
}
