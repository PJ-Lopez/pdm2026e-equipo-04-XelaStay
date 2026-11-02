import 'package:flutter_test/flutter_test.dart';
import 'package:xelastay/features/stays/data/models/stay_model.dart';
import 'package:xelastay/features/stays/domain/centro_del_mapa.dart';
import 'package:xelastay/features/stays/domain/entities/stay.dart';

void main() {
  Stay stay(String id, {double? lat, double? lng}) => Stay(
    id: id,
    title: id,
    propertyType: 'Casa',
    capacity: 2,
    priceAmount: 25000,
    currency: 'GTQ',
    ratingAverage: 0,
    ratingCount: 0,
    zone: 'Zona 1',
    reference: '',
    verificationStatus: 'verified',
    latitud: lat,
    longitud: lng,
  );

  group('centroDelMapa', () {
    test('promedia solo los alojamientos con coordenadas', () {
      final centro = centroDelMapa([
        stay('a', lat: 14.80, lng: -91.50),
        stay('b', lat: 14.84, lng: -91.54),
        stay('sin ubicación'),
      ]);
      expect(centro.latitude, closeTo(14.82, 1e-9));
      expect(centro.longitude, closeTo(-91.52, 1e-9));
    });

    test('sin coordenadas usa el centro de Xela', () {
      expect(centroDelMapa([stay('a')]), centroDeXela);
      expect(centroDelMapa(const []), centroDeXela);
    });
  });

  group('StayModel lee las coordenadas del API', () {
    Stay leer(Map<String, dynamic> json) =>
        StayModel.fromJson({'id': 'x', 'title': 'X', ...json});

    test('en location.latitude / longitude', () {
      final s = leer({
        'location': {'zone': 'Zona 3', 'latitude': 14.83, 'longitude': -91.51},
      });
      expect(s.latitud, 14.83);
      expect(s.longitud, -91.51);
      expect(s.tieneUbicacion, isTrue);
    });

    test('en location.coordinates, como texto o en la raíz', () {
      expect(
        leer({
          'location': {
            'coordinates': {'lat': '14.83', 'lng': '-91.51'},
          },
        }).longitud,
        -91.51,
      );
      expect(leer({'latitude': 14.8, 'longitude': -91.5}).latitud, 14.8);
    });

    test('si no vienen, quedan en null y no sale en el mapa', () {
      final s = leer({
        'location': {'zone': 'Zona 1'},
      });
      expect(s.latitud, isNull);
      expect(s.tieneUbicacion, isFalse);
    });
  });
}
