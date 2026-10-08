import '../entities/host_stay.dart';
import '../repositories/hosts_repository.dart';

class CreateHostStay {
  const CreateHostStay(this._repository);
  final HostsRepository _repository;

  Future<HostStay> call(HostStayDraft draft) => _repository.createStay(draft);
}
