import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

import '../core/errors/app_exception.dart';
import '../data/repositories/auth_repository.dart';
import 'mensajes_error.dart';
import 'sesion_controller.dart';

/// Eliminación permanente de la cuenta (derecho de eliminación de datos personales).
class EliminarCuentaController extends GetxController {
  EliminarCuentaController({required this._repositorio, required this._sesion});

  final AuthRepository _repositorio;
  final SesionController _sesion;

  final TextEditingController clave = TextEditingController();
  final RxBool entiendo = false.obs;
  final RxBool cargando = false.obs;
  final RxBool visible = false.obs;
  final RxnString errorClave = RxnString();
  final RxnString errorGeneral = RxnString();

  void alternarVisible() => visible.toggle();

  void marcarEntiendo(bool? valor) => entiendo.value = valor ?? false;

  Future<void> eliminar() async {
    if (cargando.value || !entiendo.value) return;
    errorGeneral.value = null;
    errorClave.value = clave.text.isEmpty ? 'Ingresa tu clave para confirmar.' : null;
    if (errorClave.value != null) return;

    cargando.value = true;
    try {
      await _repositorio.eliminarCuenta(clave.text);
      _sesion.salirSinRevocar('Tu cuenta y tus consultas fueron eliminadas.');
    } on BadRequestException catch (e) {
      errorClave.value = e.detalle ?? 'La clave es incorrecta.';
    } on AppException catch (e) {
      if (!MensajesError.requiereLogin(e)) errorGeneral.value = MensajesError.de(e);
    } finally {
      cargando.value = false;
    }
  }

  @override
  void onClose() {
    clave.dispose();
    super.onClose();
  }
}
