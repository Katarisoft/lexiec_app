import '../datasources/remote_planes_datasource.dart';
import '../models/plan.dart';

class PlanesRepository {
  PlanesRepository(this._remoto);

  final RemotePlanesDatasource _remoto;

  Future<List<PlanCatalogo>> catalogo() => _remoto.catalogo();

  Future<EstadoPlan> estado() => _remoto.estado();
}
