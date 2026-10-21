import 'package:dio/dio.dart';

import '../../core/network/api_client.dart';
import '../models/perfil.dart';
import '../models/tokens_sesion.dart';

/// Endpoints de cuenta (guía de la API, § 3).
class RemoteAuthDatasource {
  RemoteAuthDatasource(this._api);

  final ApiClient _api;

  /// `POST /auth/token` (formulario `x-www-form-urlencoded`, no JSON).
  Future<TokensSesion> iniciarSesion(String usuario, String clave) => ApiClient.ejecutar(() async {
    final r = await _api.dio.post<Map<String, dynamic>>(
      '/auth/token',
      data: {'username': usuario, 'password': clave},
      options: Options(contentType: Headers.formUrlEncodedContentType),
    );
    return TokensSesion.fromJson(r.data!);
  });

  /// `POST /auth/registro` → 201 con el perfil (no devuelve token).
  Future<Perfil> registrar({
    required String usuario,
    required String clave,
    required String codigoInvitacion,
    String? correo,
    String? nombre,
  }) => ApiClient.ejecutar(() async {
    final r = await _api.dio.post<Map<String, dynamic>>(
      '/auth/registro',
      data: {
        'usuario': usuario,
        'clave': clave,
        'codigo_invitacion': codigoInvitacion,
        'correo': ?correo,
        'nombre': ?nombre,
      },
    );
    return Perfil.fromJson(r.data!);
  });

  /// `GET /auth/me`.
  Future<Perfil> perfil() => ApiClient.ejecutar(() async {
    final r = await _api.dio.get<Map<String, dynamic>>('/auth/me');
    return Perfil.fromJson(r.data!);
  });

  /// `POST /auth/cerrar-sesion`: revoca la sesión de este dispositivo (204 siempre).
  Future<void> cerrarSesion(String refreshToken) => ApiClient.ejecutar(() async {
    await _api.dio.post<void>('/auth/cerrar-sesion', data: {'refresh_token': refreshToken});
  });
}
