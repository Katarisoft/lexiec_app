import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../core/network/almacen_tokens.dart';

/// Tokens de sesión en almacenamiento seguro (Android Keystore).
/// Nunca en shared_preferences, Hive ni registros.
class LocalTokensDatasource implements AlmacenTokens {
  LocalTokensDatasource([FlutterSecureStorage? almacenamiento])
    : _almacenamiento = almacenamiento ?? const FlutterSecureStorage();

  final FlutterSecureStorage _almacenamiento;

  static const String _claveAccess = 'lexiec.access_token';
  static const String _claveRefresh = 'lexiec.refresh_token';

  @override
  Future<String?> leerAccess() => _almacenamiento.read(key: _claveAccess);

  @override
  Future<String?> leerRefresh() => _almacenamiento.read(key: _claveRefresh);

  @override
  Future<void> guardar({required String access, String? refresh}) async {
    await _almacenamiento.write(key: _claveAccess, value: access);
    if (refresh != null) await _almacenamiento.write(key: _claveRefresh, value: refresh);
  }

  @override
  Future<void> borrar() async {
    await _almacenamiento.delete(key: _claveAccess);
    await _almacenamiento.delete(key: _claveRefresh);
  }
}
