class StayItem {
  final String id;
  final String title;
  final String location;
  final double pricePerNight;

  const StayItem({
    required this.id,
    required this.title,
    required this.location,
    required this.pricePerNight,
  });
}

abstract class IStaysStateRepository {
  Future<List<StayItem>> fetchStays({
    bool forceError = false,
    bool forceEmpty = false,
  });
}

class StaysStateRepository implements IStaysStateRepository {
  @override
  Future<List<StayItem>> fetchStays({
    bool forceError = false,
    bool forceEmpty = false,
  }) async {
    // Simula latencia de red de 600 ms
    await Future.delayed(const Duration(milliseconds: 600));

    if (forceError) {
      throw Exception('Error al conectar con la base de datos de XelaStay');
    }

    if (forceEmpty) {
      return [];
    }

    return const [
      StayItem(
        id: '1',
        title: 'Apartamento Zona 1 Centro',
        location: 'Zona 1, Quetzaltenango',
        pricePerNight: 250.00,
      ),
      StayItem(
        id: '2',
        title: 'Habitación cerca de Pradera',
        location: 'Zona 3, Quetzaltenango',
        pricePerNight: 160.00,
      ),
      StayItem(
        id: '3',
        title: 'Cabaña Los Chocoyos',
        location: 'Las Majadas, Quetzaltenango',
        pricePerNight: 420.00,
      ),
      StayItem(
        id: '4',
        title: 'Estudio Ejecutivo La Floresta',
        location: 'Zona 9, Quetzaltenango',
        pricePerNight: 280.00,
      ),
    ];
  }
}
