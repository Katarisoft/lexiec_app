import '../datasources/remote_documentos_datasource.dart';
import '../models/documento.dart';

class DocumentosRepository {
  DocumentosRepository(this._remoto);

  final RemoteDocumentosDatasource _remoto;

  Future<List<Documento>> listar() => _remoto.listar();
}
