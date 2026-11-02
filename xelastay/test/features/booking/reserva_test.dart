import 'package:flutter_test/flutter_test.dart';
import 'package:xelastay/core/utils/formatos.dart';
import 'package:xelastay/features/booking/domain/entities/reserva.dart';

void main() {
  Reserva reserva(EstadoReserva estado, DateTime entrada, DateTime salida) =>
      Reserva(
        id: 1,
        stayId: 'centro',
        titulo: 'Apartamento en el centro de Xela',
        zona: 'Zona 1',
        precioNocheCentavos: 25000,
        entrada: entrada,
        salida: salida,
        huespedes: 2,
        huespedId: 'u1',
        huespedNombre: 'Ana',
        estado: estado,
        creadaEn: DateTime(2026, 11, 2),
      );

  group('Desglose', () {
    test('noches por precio más 10 % de servicio, en centavos', () {
      final d = Desglose.de(25000, 2);
      expect(d.subtotalCentavos, 50000);
      expect(d.servicioCentavos, 5000);
      expect(d.totalCentavos, 55000);
    });

    test('la tarifa redondea al centavo más cercano sin usar double', () {
      expect(Desglose.de(33333, 1).servicioCentavos, 3333); // 3333.3
      expect(Desglose.de(33335, 1).servicioCentavos, 3334); // 3333.5
    });
  });

  group('Reserva', () {
    final hoy = DateTime(2026, 11, 10, 15, 30);

    test('cuenta noches por días, no por horas', () {
      final r = reserva(
        EstadoReserva.pendiente,
        DateTime(2026, 11, 14),
        DateTime(2026, 11, 16),
      );
      expect(r.noches, 2);
      expect(r.desglose.totalCentavos, 55000);
    });

    test('cada estado cae en su pestaña de Reservas', () {
      final futura = (DateTime(2026, 11, 14), DateTime(2026, 11, 16));
      final pasada = (DateTime(2026, 11, 1), DateTime(2026, 11, 3));
      GrupoReserva g(EstadoReserva e, (DateTime, DateTime) f) =>
          reserva(e, f.$1, f.$2).grupo(hoy);

      expect(g(EstadoReserva.pendiente, futura), GrupoReserva.pendientes);
      expect(g(EstadoReserva.aceptada, futura), GrupoReserva.pendientes);
      expect(g(EstadoReserva.confirmada, futura), GrupoReserva.proximas);
      expect(g(EstadoReserva.confirmada, pasada), GrupoReserva.anteriores);
      expect(g(EstadoReserva.cancelada, futura), GrupoReserva.anteriores);
      expect(g(EstadoReserva.rechazada, futura), GrupoReserva.anteriores);
      expect(g(EstadoReserva.completada, pasada), GrupoReserva.anteriores);
    });

    test('solo pendiente y aceptada se pueden cancelar', () {
      expect(EstadoReserva.values.where((e) => e.cancelable), [
        EstadoReserva.pendiente,
        EstadoReserva.aceptada,
      ]);
    });
  });

  group('formatos', () {
    test('quetzales con comas y dos decimales', () {
      expect(quetzales(132000), 'Q 1,320.00');
      expect(quetzales(5), 'Q 0.05');
      expect(quetzales(123456789), 'Q 1,234,567.89');
    });

    test('fechas ISO se leen y escriben igual y ordenan como texto', () {
      expect(fechaIso(DateTime(2026, 3, 5, 18)), '2026-03-05');
      expect(desdeIso('2026-03-05'), DateTime(2026, 3, 5));
      expect('2026-03-05'.compareTo('2026-11-01') < 0, isTrue);
      expect(
        rangoFechas(DateTime(2026, 11, 14), DateTime(2026, 11, 16)),
        '14 nov – 16 nov',
      );
    });
  });
}
