import 'package:hive/hive.dart';

/// Preferencias locales sin datos personales (Hive, caja sin cifrar).
class LocalPreferenciasDatasource {
  static const String caja = 'preferencias';
  static const String _bienvenidaVista = 'bienvenida_vista';
  static const String _tema = 'tema';

  Future<Box<dynamic>> _abrir() async => Hive.isBoxOpen(caja) ? Hive.box<dynamic>(caja) : Hive.openBox<dynamic>(caja);

  Future<bool> bienvenidaVista() async => (await _abrir()).get(_bienvenidaVista, defaultValue: false) as bool;

  Future<void> marcarBienvenidaVista() async => (await _abrir()).put(_bienvenidaVista, true);

  /// 'sistema' | 'claro' | 'oscuro'.
  Future<String> tema() async => (await _abrir()).get(_tema, defaultValue: 'sistema') as String;

  Future<void> guardarTema(String tema) async => (await _abrir()).put(_tema, tema);
}
