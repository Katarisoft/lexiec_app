import 'package:get/get.dart';

import '../../controllers/cambiar_clave_controller.dart';
import '../../controllers/eliminar_cuenta_controller.dart';
import '../../controllers/normas_controller.dart';
import '../../controllers/perfil_controller.dart';
import '../../controllers/sesion_controller.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/repositories/documentos_repository.dart';

class PerfilBinding extends Bindings {
  @override
  void dependencies() => Get.lazyPut<PerfilController>(
    () => PerfilController(repositorio: Get.find<AuthRepository>(), sesion: Get.find<SesionController>()),
  );
}

class CambiarClaveBinding extends Bindings {
  @override
  void dependencies() => Get.lazyPut<CambiarClaveController>(
    () => CambiarClaveController(repositorio: Get.find<AuthRepository>(), sesion: Get.find<SesionController>()),
  );
}

class EliminarCuentaBinding extends Bindings {
  @override
  void dependencies() => Get.lazyPut<EliminarCuentaController>(
    () => EliminarCuentaController(repositorio: Get.find<AuthRepository>(), sesion: Get.find<SesionController>()),
  );
}

class NormasBinding extends Bindings {
  @override
  void dependencies() =>
      Get.lazyPut<NormasController>(() => NormasController(repositorio: Get.find<DocumentosRepository>()));
}
