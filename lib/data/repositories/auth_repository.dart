import '../../core/errors/app_exception.dart';
import '../../core/network/almacen_tokens.dart';
import '../datasources/local_preferencias_datasource.dart';
import '../datasources/remote_auth_datasource.dart';
import '../models/perfil.dart';

/// Sesión del usuario: combina la API de cuentas, el almacenamiento seguro de
/// tokens y las preferencias locales.
class AuthRepository {
  AuthRepository({required this._remoto, required this._tokens, required this._preferencias});

  final RemoteAuthDatasource _remoto;
  final AlmacenTokens _tokens;
  final LocalPreferenciasDatasource _preferencias;

  Future<bool> tieneSesionGuardada() async => await _tokens.leerRefresh() != null || await _tokens.leerAccess() != null;

  /// Inicia sesión, guarda ambos tokens en almacenamiento seguro y devuelve el perfil.
  Future<Perfil> iniciarSesion(String usuario, String clave) async {
    final tokens = await _remoto.iniciarSesion(usuario.trim(), clave);
    await _tokens.guardar(access: tokens.accessToken, refresh: tokens.refreshToken);
    return _remoto.perfil();
  }

  /// Crea la cuenta y, como el registro no devuelve token, inicia sesión a continuación.
  Future<Perfil> registrar({
    required String usuario,
    required String clave,
    required String codigoInvitacion,
    String? correo,
    String? nombre,
  }) async {
    await _remoto.registrar(
      usuario: usuario.trim(),
      clave: clave,
      codigoInvitacion: codigoInvitacion.trim(),
      correo: correo,
      nombre: nombre,
    );
    return iniciarSesion(usuario, clave);
  }

  Future<Perfil> perfil() => _remoto.perfil();

  /// Cierra la sesión local siempre; revocarla en el servidor es lo mejor posible (sin red, sigue cerrada aquí).
  Future<void> cerrarSesion() async {
    final refresh = await _tokens.leerRefresh();
    await _tokens.borrar();
    if (refresh == null) return;
    try {
      await _remoto.cerrarSesion(refresh);
    } on AppException {
      // El refresh token ya no está en el dispositivo; caducará en el servidor.
    }
  }

  /// Cambia la clave y guarda los tokens nuevos (los anteriores dejan de servir).
  Future<void> cambiarClave(String actual, String nueva) async {
    final tokens = await _remoto.cambiarClave(actual, nueva);
    await _tokens.guardar(access: tokens.accessToken, refresh: tokens.refreshToken);
  }

  /// Elimina la cuenta en el servidor y borra los tokens del dispositivo.
  Future<void> eliminarCuenta(String clave) async {
    await _remoto.eliminarCuenta(clave);
    await _tokens.borrar();
  }

  Future<bool> bienvenidaVista() => _preferencias.bienvenidaVista();

  Future<void> marcarBienvenidaVista() => _preferencias.marcarBienvenidaVista();
}
