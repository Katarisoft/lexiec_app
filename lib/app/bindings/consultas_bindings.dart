import 'package:get/get.dart';

import '../../controllers/consulta_controller.dart';
import '../../controllers/conversaciones_controller.dart';
import '../../controllers/sesion_controller.dart';
import '../../data/repositories/chat_repository.dart';
import '../../data/repositories/conversaciones_repository.dart';

class ConsultasBinding extends Bindings {
  @override
  void dependencies() => Get.lazyPut<ConversacionesController>(
    () => ConversacionesController(
      repositorio: Get.find<ConversacionesRepository>(),
      sesion: Get.find<SesionController>(),
    ),
  );
}

/// El detalle reutiliza el ConversacionesController de la lista (estado compartido).
class ConsultaBinding extends Bindings {
  @override
  void dependencies() => Get.lazyPut<ConsultaController>(
    () => ConsultaController(
      repositorio: Get.find<ConversacionesRepository>(),
      chat: Get.find<ChatRepository>(),
      lista: Get.find<ConversacionesController>(),
      id: Get.parameters['id']!,
    ),
  );
}
