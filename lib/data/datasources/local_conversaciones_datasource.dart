import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hive/hive.dart';

import '../models/conversacion.dart';

/// Proveedor de la clave de cifrado de la caché (32 bytes).
abstract interface class ClaveCache {
  Future<List<int>> obtener();
}

/// Clave AES generada una vez y guardada en almacenamiento seguro (Android Keystore).
class ClaveCacheSegura implements ClaveCache {
  ClaveCacheSegura([FlutterSecureStorage? almacenamiento])
    : _almacenamiento = almacenamiento ?? const FlutterSecureStorage();

  final FlutterSecureStorage _almacenamiento;
  static const String _nombre = 'lexiec.clave_cache';

  @override
  Future<List<int>> obtener() async {
    final guardada = await _almacenamiento.read(key: _nombre);
    if (guardada != null) return base64Url.decode(guardada);
    final nueva = Hive.generateSecureKey();
    await _almacenamiento.write(key: _nombre, value: base64UrlEncode(nueva));
    return nueva;
  }
}

/// Historial local de consultas (Hive cifrado con AES-256): la lista y el detalle de cada
/// conversación. Sobrevive al cierre de la app y permite consultar sin conexión.
/// Las conversaciones pueden contener datos personales, por eso la caja va cifrada.
class LocalConversacionesDatasource {
  LocalConversacionesDatasource(this._clave);

  final ClaveCache _clave;
  static const String caja = 'conversaciones';
  static const String _lista = 'lista';
  static const String _duenio = 'usuario';
  static const String _prefijoDetalle = 'detalle:';

  Future<Box<dynamic>> _abrir() async {
    if (Hive.isBoxOpen(caja)) return Hive.box<dynamic>(caja);
    return Hive.openBox<dynamic>(caja, encryptionCipher: HiveAesCipher(await _clave.obtener()));
  }

  /// Asegura que la caché pertenece a [usuario]; si es de otra cuenta, la vacía.
  Future<void> asignarUsuario(String usuario) async {
    final box = await _abrir();
    if (box.get(_duenio) != usuario) {
      await box.clear();
      await box.put(_duenio, usuario);
    }
  }

  Future<List<Conversacion>?> leerLista() async {
    final datos = (await _abrir()).get(_lista) as List<dynamic>?;
    return datos?.map((e) => Conversacion.fromJson(_mapa(e))).toList();
  }

  Future<void> guardarLista(List<Conversacion> conversaciones) async =>
      (await _abrir()).put(_lista, conversaciones.map((c) => c.toJson()).toList());

  Future<ConversacionDetalle?> leerDetalle(String id) async {
    final datos = (await _abrir()).get('$_prefijoDetalle$id');
    return datos == null ? null : ConversacionDetalle.fromJson(_mapa(datos));
  }

  Future<void> guardarDetalle(ConversacionDetalle detalle) async =>
      (await _abrir()).put('$_prefijoDetalle${detalle.conversacion.id}', detalle.toJson());

  Future<void> eliminar(String id) async {
    final box = await _abrir();
    final lista = await leerLista();
    if (lista != null) await guardarLista(lista.where((c) => c.id != id).toList());
    await box.delete('$_prefijoDetalle$id');
  }

  /// Al cerrar sesión: no deja historial de la cuenta en el dispositivo.
  Future<void> vaciar() async => (await _abrir()).clear();

  /// Hive devuelve `Map<dynamic, dynamic>` anidados: se normalizan vía JSON.
  static Map<String, dynamic> _mapa(Object? valor) => jsonDecode(jsonEncode(valor)) as Map<String, dynamic>;
}
