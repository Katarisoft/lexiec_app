import 'package:intl/intl.dart';

/// Fechas en español, relativas a [ahora] (inyectable en pruebas).
abstract final class FormatoFecha {
  static DateTime _dia(DateTime f) => DateTime(f.year, f.month, f.day);

  /// "Hoy, 14:20" · "Ayer, 09:05" · "lunes, 18:30" · "12 oct." · "12 oct. 2025"
  static String relativa(DateTime fecha, {DateTime? ahora}) {
    final local = fecha.toLocal();
    final hoy = _dia(ahora ?? DateTime.now());
    final dias = hoy.difference(_dia(local)).inDays;
    final hora = DateFormat.Hm('es').format(local);
    if (dias <= 0) return 'Hoy, $hora';
    if (dias == 1) return 'Ayer, $hora';
    if (dias < 7) return '${DateFormat.EEEE('es').format(local)}, $hora';
    return local.year == hoy.year ? DateFormat('d MMM', 'es').format(local) : DateFormat('d MMM y', 'es').format(local);
  }

  /// Encabezado de grupo en la lista.
  static String grupo(DateTime fecha, {DateTime? ahora}) {
    final dias = _dia(ahora ?? DateTime.now()).difference(_dia(fecha.toLocal())).inDays;
    if (dias <= 0) return 'Hoy';
    if (dias == 1) return 'Ayer';
    if (dias < 7) return 'Últimos 7 días';
    return 'Anteriores';
  }
}
