import '../../domain/entities/host_stay.dart';

class HostStayModel extends HostStay {
  const HostStayModel({required super.id, required super.title, required super.status});

  factory HostStayModel.fromJson(Map<String, dynamic> json) => HostStayModel(
    id: json['id']?.toString() ?? '',
    title: json['title']?.toString() ?? 'Alojamiento',
    status: json['status']?.toString() ?? 'pending_verification',
  );
}
