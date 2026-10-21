import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

import '../core/errors/app_exception.dart';
import '../data/repositories/auth_repository.dart';
import '../widgets/avisos.dart';
import 'mensajes_error.dart';
import 'sesion_controller.dart';
import 'validadores.dart';

class CambiarClaveController extends GetxController {
  CambiarClaveController({required this._repositorio, required this._sesion});

  final AuthRepository _repositorio;
  final SesionController _sesion;

  // Claves de error = nombres de campo de la API (clave_actual, clave_nueva).
  final TextEditingController actual = TextEditingController();
  final TextEditingController nueva = TextEditingController();
  final TextEditingController confirmacion = TextEditingController();

  final RxBool cargando = false.obs;
  final RxBool visible = false.obs;
  final RxnString errorGeneral = RxnString();
  final RxMap<String, String> errores = <String, String>{}.obs;

  void alternarVisible() => visible.toggle();

  Future<void> guardar() async {
    if (cargando.value) return;
    errorGeneral.value = null;
    final usuario = _sesion.perfil.value?.usuario ?? '';
    errores.assignAll({
      'clave_actual': ?Validadores.requerido(actual.text, 'Ingresa tu clave actual.'),
      'clave_nueva': ?(nueva.text.isNotEmpty && nueva.text == actual.text
          ? 'La clave nueva debe ser distinta de la actual.'
          : Validadores.claveNueva(nueva.text, usuario: usuario)),
      'confirmacion': ?Validadores.confirmacion(confirmacion.text, nueva.text),
    });
    if (errores.isNotEmpty) return;

    cargando.value = true;
    try {
      await _repositorio.cambiarClave(actual.text, nueva.text);
      Get.back<void>();
      mostrarAviso('Clave actualizada. Cerramos tu sesión en los demás dispositivos.');
    } on BadRequestException catch (e) {
      final detalle = e.detalle ?? MensajesError.de(e);
      errores[detalle.toLowerCase().contains('actual') ? 'clave_actual' : 'clave_nueva'] = detalle;
    } on ValidationException catch (e) {
      errores.assignAll(Map.of(e.campos)..remove(ValidationException.general));
      errorGeneral.value = e.campos[ValidationException.general];
    } on AppException catch (e) {
      if (!MensajesError.requiereLogin(e)) errorGeneral.value = MensajesError.de(e);
    } finally {
      cargando.value = false;
    }
  }

  @override
  void onClose() {
    for (final c in [actual, nueva, confirmacion]) {
      c.dispose();
    }
    super.onClose();
  }
}
