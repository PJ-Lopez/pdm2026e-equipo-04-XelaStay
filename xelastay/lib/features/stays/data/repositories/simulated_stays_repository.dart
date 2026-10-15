import '../../domain/entities/stay.dart';
import '../../domain/repositories/stays_repository.dart';

enum StaysScenario { data, empty, error }

/// Repositorio para demostrar estados sin conexión al API.
class SimulatedStaysRepository implements StaysRepository {
  const SimulatedStaysRepository({
    this.scenario = StaysScenario.data,
    this.latency = const Duration(milliseconds: 800),
  });

  final StaysScenario scenario;
  final Duration latency;

  @override
  Future<List<Stay>> getPublicStays() async {
    await Future<void>.delayed(latency);
    return switch (scenario) {
      StaysScenario.error => throw Exception('Error simulado del catálogo'),
      StaysScenario.empty => const [],
      StaysScenario.data => const [
        Stay(
          id: 'demo-centro',
          title: 'Apartamento en el centro de Xela',
          propertyType: 'Apartamento',
          capacity: 2,
          priceAmount: 25000,
          currency: 'GTQ',
          ratingAverage: 4.8,
          ratingCount: 12,
          zone: 'Zona 1',
          reference: 'Cerca del Parque Central',
          verificationStatus: 'verified',
        ),
        Stay(
          id: 'demo-cabana',
          title: 'Cabaña con vista a las montañas',
          propertyType: 'Cabaña',
          capacity: 4,
          priceAmount: 45000,
          currency: 'GTQ',
          ratingAverage: 0,
          ratingCount: 0,
          zone: 'Las afueras de Xela',
          reference: 'Camino a las montañas',
          verificationStatus: 'pending',
        ),
      ],
    };
  }
}
