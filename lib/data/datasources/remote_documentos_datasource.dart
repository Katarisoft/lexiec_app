import '../../core/network/api_client.dart';
import '../models/documento.dart';

/// `GET /documentos`: normas indexadas (sobre qué se puede preguntar).
class RemoteDocumentosDatasource {
  RemoteDocumentosDatasource(this._api);

  final ApiClient _api;

  Future<List<Documento>> listar() => ApiClient.ejecutar(() async {
    final r = await _api.dio.get<Map<String, dynamic>>('/documentos');
    return (r.data!['documentos'] as List<dynamic>).map((e) => Documento.fromJson(e as Map<String, dynamic>)).toList();
  });
}
