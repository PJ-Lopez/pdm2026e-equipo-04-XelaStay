/// Formatos en español para dinero y fechas, sin depender de `intl`.
library;

const _meses = [
  'ene',
  'feb',
  'mar',
  'abr',
  'may',
  'jun',
  'jul',
  'ago',
  'sep',
  'oct',
  'nov',
  'dic',
];

/// 132000 → "Q 1,320.00". El dinero siempre llega en centavos (`int`).
String quetzales(int centavos) {
  final negativo = centavos < 0;
  final valor = centavos.abs();
  final enteros = (valor ~/ 100).toString();
  final decimales = (valor % 100).toString().padLeft(2, '0');
  final conComas = StringBuffer();
  for (var i = 0; i < enteros.length; i++) {
    if (i > 0 && (enteros.length - i) % 3 == 0) conComas.write(',');
    conComas.write(enteros[i]);
  }
  return '${negativo ? '-' : ''}Q $conComas.$decimales';
}

/// Quita la hora: las reservas se cuentan por días, no por horas.
DateTime soloFecha(DateTime fecha) =>
    DateTime(fecha.year, fecha.month, fecha.day);

/// "2026-11-14": así se guardan las fechas en SQLite. El orden del texto es
/// el mismo que el de las fechas, por eso se pueden comparar con < y >.
String fechaIso(DateTime fecha) =>
    '${fecha.year.toString().padLeft(4, '0')}-'
    '${fecha.month.toString().padLeft(2, '0')}-'
    '${fecha.day.toString().padLeft(2, '0')}';

DateTime desdeIso(String texto) {
  final partes = texto.split('-').map(int.parse).toList();
  return DateTime(partes[0], partes[1], partes[2]);
}

/// "14 nov".
String fechaCorta(DateTime fecha) => '${fecha.day} ${_meses[fecha.month - 1]}';

/// "14 nov – 16 nov".
String rangoFechas(DateTime entrada, DateTime salida) =>
    '${fechaCorta(entrada)} – ${fechaCorta(salida)}';

/// "14 nov, 18:05".
String fechaHora(DateTime momento) =>
    '${fechaCorta(momento)}, '
    '${momento.hour.toString().padLeft(2, '0')}:'
    '${momento.minute.toString().padLeft(2, '0')}';
