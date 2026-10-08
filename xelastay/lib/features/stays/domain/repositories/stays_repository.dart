import '../entities/stay.dart';

abstract interface class StaysRepository {
  Future<List<Stay>> getPublicStays();
}
