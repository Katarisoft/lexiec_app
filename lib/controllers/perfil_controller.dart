import 'package:get/get.dart';

import '../app/routes/app_routes.dart';
import '../core/errors/app_exception.dart';
import '../data/models/perfil.dart';
import '../data/repositories/auth_repository.dart';
import 'sesion_controller.dart';

/// "Mi cuenta": datos del perfil y acciones de la cuenta.
class PerfilController extends GetxController {
  PerfilController({required this._repositorio, required this._sesion});

  final AuthRepository _repositorio;
  final SesionController _sesion;

  Rxn<Perfil> get perfil => _sesion.perfil;

  @override
  void onInit() {
    super.onInit();
    _actualizar();
  }

  /// Refresca el perfil sin bloquear la pantalla (si falla, se muestra el que ya se tiene).
  Future<void> _actualizar() async {
    try {
      _sesion.establecer(await _repositorio.perfil());
    } on AppException {
      // sin conexión: se conserva el perfil guardado en memoria
    }
  }

  Future<void> cerrarSesion() => _sesion.cerrarSesion();

  void irACambiarClave() => Get.toNamed<void>(AppRoutes.cambiarClave);

  void irAEliminarCuenta() => Get.toNamed<void>(AppRoutes.eliminarCuenta);

  void irANormas() => Get.toNamed<void>(AppRoutes.normas);

  void irAPlan() => Get.toNamed<void>(AppRoutes.plan);
}
