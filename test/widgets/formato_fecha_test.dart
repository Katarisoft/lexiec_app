import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:lexiec/widgets/formato_fecha.dart';

void main() {
  setUpAll(() => initializeDateFormatting('es'));
  final ahora = DateTime(2026, 10, 21, 18);

  test('fechas relativas en español', () {
    expect(FormatoFecha.relativa(DateTime(2026, 10, 21, 9, 5), ahora: ahora), 'Hoy, 9:05');
    expect(FormatoFecha.relativa(DateTime(2026, 10, 20, 22, 0), ahora: ahora), 'Ayer, 22:00');
    expect(FormatoFecha.relativa(DateTime(2026, 10, 3), ahora: ahora), '3 oct');
    expect(FormatoFecha.relativa(DateTime(2025, 12, 1), ahora: ahora), contains('2025'));
  });

  test('grupos de la lista', () {
    expect(FormatoFecha.grupo(DateTime(2026, 10, 21, 1), ahora: ahora), 'Hoy');
    expect(FormatoFecha.grupo(DateTime(2026, 10, 20), ahora: ahora), 'Ayer');
    expect(FormatoFecha.grupo(DateTime(2026, 10, 17), ahora: ahora), 'Últimos 7 días');
    expect(FormatoFecha.grupo(DateTime(2026, 9, 1), ahora: ahora), 'Anteriores');
  });
}
