import '../entities/host_stay.dart';

abstract interface class HostsRepository {
  Future<HostStay> createStay(HostStayDraft draft);
}
