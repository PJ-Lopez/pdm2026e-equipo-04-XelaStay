import '../../domain/entities/stay.dart';

class StayModel extends Stay {
  const StayModel({
    required super.id,
    required super.title,
    required super.propertyType,
    required super.capacity,
    required super.priceAmount,
    required super.currency,
    required super.ratingAverage,
    required super.ratingCount,
    required super.zone,
    required super.reference,
    required super.verificationStatus,
    super.coverPhotoUrl,
    super.isFavorite,
  });

  factory StayModel.fromJson(Map<String, dynamic> json) {
    final price = _map(json['pricePerNight']);
    final rating = _map(json['rating']);
    final location = _map(json['location']);
    final photoUrl = json['coverPhotoUrl']?.toString();
    return StayModel(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? 'Alojamiento en Xela',
      propertyType: json['propertyType']?.toString() ?? 'Alojamiento',
      capacity: _integer(json['capacity']),
      priceAmount: _integer(price['amount']),
      currency: price['currency']?.toString() ?? 'GTQ',
      ratingAverage: _decimal(rating['average']),
      ratingCount: _integer(rating['count']),
      zone: location['zone']?.toString() ?? 'Quetzaltenango',
      reference: location['reference']?.toString() ?? '',
      verificationStatus: json['verificationStatus']?.toString() ?? 'pending',
      coverPhotoUrl: photoUrl == null || photoUrl.isEmpty ? null : photoUrl,
      isFavorite: json['isFavorite'] == true,
    );
  }

  static Map<String, dynamic> _map(Object? value) =>
      value is Map<String, dynamic> ? value : const {};

  static int _integer(Object? value) =>
      value is num ? value.round() : int.tryParse(value?.toString() ?? '') ?? 0;

  static double _decimal(Object? value) =>
      value is num ? value.toDouble() : double.tryParse(value?.toString() ?? '') ?? 0;
}
