class HostStay {
  const HostStay({required this.id, required this.title, required this.status});

  final String id;
  final String title;
  final String status;

  bool get isPendingVerification => status == 'pending_verification';
}

class HostStayDraft {
  const HostStayDraft({
    required this.title,
    required this.description,
    required this.propertyType,
    required this.capacity,
    required this.bedrooms,
    required this.beds,
    required this.bathrooms,
    required this.priceInQuetzales,
    required this.latitude,
    required this.longitude,
    required this.address,
    required this.zone,
    required this.localReference,
    this.rules,
  });

  final String title;
  final String description;
  final String propertyType;
  final int capacity;
  final int bedrooms;
  final int beds;
  final int bathrooms;
  final double priceInQuetzales;
  final double latitude;
  final double longitude;
  final String address;
  final String zone;
  final String localReference;
  final String? rules;
}
