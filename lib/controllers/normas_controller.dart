import 'package:get/get.dart';

import '../core/errors/app_exception.dart';
import '../data/models/documento.dart';
import '../data/repositories/documentos_repository.dart';
import 'mensajes_error.dart';
import 'view_status.dart';

/// Normas disponibles: sobre qué documentos responde el asistente.
class NormasController extends GetxController {
  NormasController({required this._repositorio});

  final DocumentosRepository _repositorio;

  final Rx<ViewStatus> estado = ViewStatus.loading.obs;
  final RxString mensajeError = ''.obs;
  final RxList<Documento> documentos = <Documento>[].obs;

  @override
  void onInit() {
    super.onInit();
    cargar();
  }

  Future<void> cargar() async {
    estado.value = ViewStatus.loading;
    try {
      documentos.assignAll(await _repositorio.listar());
      estado.value = documentos.isEmpty ? ViewStatus.empty : ViewStatus.success;
    } on AppException catch (e) {
      if (MensajesError.requiereLogin(e)) return;
      mensajeError.value = MensajesError.de(e);
      estado.value = ViewStatus.error;
    }
  }
}
