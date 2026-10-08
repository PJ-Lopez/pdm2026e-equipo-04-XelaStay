import '../entities/stay.dart';
import '../repositories/stays_repository.dart';

class GetPublicStays {
  const GetPublicStays(this._repository);

  final StaysRepository _repository;

  Future<List<Stay>> call() => _repository.getPublicStays();
}
