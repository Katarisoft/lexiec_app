import 'package:get/get.dart';

import '../../controllers/bienvenida_controller.dart';
import '../../controllers/inicio_controller.dart';
import '../../controllers/login_controller.dart';
import '../../controllers/registro_controller.dart';
import '../../controllers/sesion_controller.dart';
import '../../data/repositories/auth_repository.dart';

class InicioBinding extends Bindings {
  @override
  // put (no lazyPut): la pantalla de inicio no lee el controlador, y este debe ejecutar onReady.
  void dependencies() => Get.put<InicioController>(
    InicioController(repositorio: Get.find<AuthRepository>(), sesion: Get.find<SesionController>()),
  );
}

class BienvenidaBinding extends Bindings {
  @override
  void dependencies() =>
      Get.lazyPut<BienvenidaController>(() => BienvenidaController(repositorio: Get.find<AuthRepository>()));
}

class LoginBinding extends Bindings {
  @override
  void dependencies() => Get.lazyPut<LoginController>(
    () => LoginController(repositorio: Get.find<AuthRepository>(), sesion: Get.find<SesionController>()),
  );
}

class RegistroBinding extends Bindings {
  @override
  void dependencies() => Get.lazyPut<RegistroController>(
    () => RegistroController(repositorio: Get.find<AuthRepository>(), sesion: Get.find<SesionController>()),
  );
}
