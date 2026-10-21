import 'package:flutter/material.dart';

import '../datasources/local_preferencias_datasource.dart';

/// Preferencias de la app guardadas en el dispositivo.
class PreferenciasRepository {
  PreferenciasRepository(this._local);

  final LocalPreferenciasDatasource _local;

  Future<ThemeMode> tema() async => switch (await _local.tema()) {
    'claro' => ThemeMode.light,
    'oscuro' => ThemeMode.dark,
    _ => ThemeMode.system,
  };

  Future<void> guardarTema(ThemeMode modo) => _local.guardarTema(switch (modo) {
    ThemeMode.light => 'claro',
    ThemeMode.dark => 'oscuro',
    ThemeMode.system => 'sistema',
  });
}
