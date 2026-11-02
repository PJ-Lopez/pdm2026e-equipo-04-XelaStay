import 'package:flutter_test/flutter_test.dart';
import 'package:xelastay/features/stays/domain/entities/stay.dart';
import 'package:xelastay/features/stays/domain/filtros_catalogo.dart';

void main() {
  const centro = Stay(
    id: 'centro',
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
  );
  const cabana = Stay(
    id: 'cabana',
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
  );
  const todos = [centro, cabana];

  List<String> ids(FiltrosCatalogo f) =>
      f.aplicar(todos).map((s) => s.id).toList();

  test('sin filtros pasan todos', () {
    expect(ids(const FiltrosCatalogo()), ['centro', 'cabana']);
    expect(const FiltrosCatalogo().tieneChips, isFalse);
  });

  test('cada chip filtra por su regla', () {
    const base = FiltrosCatalogo();
    expect(ids(base.alternarVerificados()), ['centro']);
    expect(ids(base.alternarEconomico()), ['centro']); // hasta Q 300
    expect(ids(base.alternarGrupo()), ['cabana']); // 3 o más huéspedes
  });

  test('los chips se combinan entre sí y con la búsqueda', () {
    final f = const FiltrosCatalogo().alternarVerificados().alternarGrupo();
    expect(f.tieneChips, isTrue);
    expect(ids(f), isEmpty);

    // La búsqueda ignora mayúsculas y revisa zona y referencia.
    expect(ids(const FiltrosCatalogo(busqueda: '  PARQUE ')), ['centro']);
    expect(ids(const FiltrosCatalogo().conBusqueda('cabaña')), ['cabana']);
  });

  test('alternar dos veces apaga el chip', () {
    final f = const FiltrosCatalogo().alternarEconomico().alternarEconomico();
    expect(f.precioMaximoCentavos, isNull);
    expect(f.tieneChips, isFalse);
  });
}
