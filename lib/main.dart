import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'app/lexiec_app.dart';
import 'core/errors/reporte_errores.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  ReporteErrores.instalar();
  await initializeDateFormatting('es');
  runApp(const LexiecApp());
}
