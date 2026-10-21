import '../../core/network/api_client.dart';
import '../models/plan.dart';

/// `GET /planes` (catálogo, público) y `GET /plan` (saldo de la cuenta).
class RemotePlanesDatasource {
  RemotePlanesDatasource(this._api);

  final ApiClient _api;

  Future<List<PlanCatalogo>> catalogo() => ApiClient.ejecutar(() async {
    final r = await _api.dio.get<List<dynamic>>('/planes');
    return r.data!.map((e) => PlanCatalogo.fromJson(e as Map<String, dynamic>)).toList();
  });

  Future<EstadoPlan> estado() => ApiClient.ejecutar(() async {
    final r = await _api.dio.get<Map<String, dynamic>>('/plan');
    return EstadoPlan.fromJson(r.data!);
  });
}
