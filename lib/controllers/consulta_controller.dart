import 'package:get/get.dart';

import '../core/errors/app_exception.dart';
import '../data/models/conversacion.dart';
import '../data/models/mensaje.dart';
import '../data/repositories/conversaciones_repository.dart';
import 'conversaciones_controller.dart';
import 'mensajes_error.dart';
import 'view_status.dart';

/// Detalle de una consulta: historial de preguntas y respuestas con sus citas.
class ConsultaController extends GetxController {
  ConsultaController({required this._repositorio, required this._lista, required this.id});

  final ConversacionesRepository _repositorio;

  /// Controlador compartido de la lista (para reflejar cambios en "Mis consultas").
  final ConversacionesController _lista;
  final String id;

  final Rx<ViewStatus> estado = ViewStatus.loading.obs;
  final RxString mensajeError = ''.obs;
  final Rxn<Conversacion> conversacion = Rxn<Conversacion>();
  final RxList<Mensaje> mensajes = <Mensaje>[].obs;
  final RxBool sinConexion = false.obs;

  String get titulo => conversacion.value?.titulo ?? 'Consulta';

  @override
  void onInit() {
    super.onInit();
    conversacion.value = _lista.conversaciones.firstWhereOrNull((c) => c.id == id);
    cargar();
  }

  Future<void> cargar() async {
    estado.value = ViewStatus.loading;
    try {
      final (detalle, desdeCache) = await _repositorio.detalle(id);
      conversacion.value = detalle.conversacion;
      mensajes.assignAll(detalle.mensajes);
      sinConexion.value = desdeCache;
      _lista.actualizar(detalle.conversacion);
      estado.value = detalle.mensajes.isEmpty ? ViewStatus.empty : ViewStatus.success;
    } on AppException catch (e) {
      if (MensajesError.requiereLogin(e)) return;
      mensajeError.value = e is NotFoundException
          ? 'Esta consulta ya no existe. Puede que se haya eliminado en otro dispositivo.'
          : MensajesError.de(e);
      estado.value = ViewStatus.error;
    }
  }

  /// Elimina la consulta (tras confirmar en la pantalla) y vuelve a la lista.
  Future<void> eliminar() async {
    final actual = conversacion.value;
    if (actual == null) return;
    if (await _lista.eliminarAhora(actual)) Get.back<void>();
  }
}
