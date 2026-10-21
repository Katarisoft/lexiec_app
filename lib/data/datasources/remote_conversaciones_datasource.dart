import '../../core/network/api_client.dart';
import '../models/conversacion.dart';

/// Endpoints de conversaciones (guía de la API, § 6.2–6.4 y 6.7).
class RemoteConversacionesDatasource {
  RemoteConversacionesDatasource(this._api);

  final ApiClient _api;

  /// `GET /conversaciones`: la más reciente primero.
  Future<List<Conversacion>> listar({int limite = 20, int desplazamiento = 0}) => ApiClient.ejecutar(() async {
    final r = await _api.dio.get<List<dynamic>>(
      '/conversaciones',
      queryParameters: {'limite': limite, 'desplazamiento': desplazamiento},
    );
    return r.data!.map((e) => Conversacion.fromJson(e as Map<String, dynamic>)).toList();
  });

  /// `POST /conversaciones` → 201.
  Future<Conversacion> crear({String? titulo}) => ApiClient.ejecutar(() async {
    final r = await _api.dio.post<Map<String, dynamic>>('/conversaciones', data: {'titulo': ?titulo});
    return Conversacion.fromJson(r.data!);
  });

  /// `GET /conversaciones/{id}` con todos sus mensajes.
  Future<ConversacionDetalle> detalle(String id) => ApiClient.ejecutar(() async {
    final r = await _api.dio.get<Map<String, dynamic>>('/conversaciones/$id');
    return ConversacionDetalle.fromJson(r.data!);
  });

  /// `DELETE /conversaciones/{id}` → 204 (permanente).
  Future<void> eliminar(String id) => ApiClient.ejecutar(() async {
    await _api.dio.delete<void>('/conversaciones/$id');
  });
}
