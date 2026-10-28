enum ReservationGroup { pending, upcoming, past }

class ReservationFilter {
  const ReservationFilter({
    this.group = ReservationGroup.pending,
    this.query = '',
  });

  final ReservationGroup group;
  final String query;

  ReservationFilter copyWith({ReservationGroup? group, String? query}) =>
      ReservationFilter(group: group ?? this.group, query: query ?? this.query);
}

class GuestReservation {
  const GuestReservation({
    required this.id,
    required this.stayName,
    required this.location,
    required this.checkIn,
    required this.checkOut,
    required this.guestCount,
    required this.group,
    required this.status,
    required this.statusMessage,
    required this.statusDetail,
    required this.createdLabel,
    required this.responseDeadline,
    required this.verified,
  });

  final String id;
  final String stayName;
  final String location;
  final DateTime checkIn;
  final DateTime checkOut;
  final int guestCount;
  final ReservationGroup group;
  final String status;
  final String statusMessage;
  final String statusDetail;
  final String createdLabel;
  final String responseDeadline;
  final bool verified;

  int get nights => checkOut.difference(checkIn).inDays;
}
