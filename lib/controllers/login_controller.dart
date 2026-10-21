import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

import '../app/routes/app_routes.dart';
import '../core/errors/app_exception.dart';
import '../data/repositories/auth_repository.dart';
import 'mensajes_error.dart';
import 'sesion_controller.dart';
import 'validadores.dart';

class LoginController extends GetxController {
  LoginController({required this._repositorio, required this._sesion});

  final AuthRepository _repositorio;
  final SesionController _sesion;

  final TextEditingController usuario = TextEditingController();
  final TextEditingController clave = TextEditingController();

  final RxBool cargando = false.obs;
  final RxBool claveVisible = false.obs;
  final RxnString errorGeneral = RxnString();
  final RxMap<String, String> errores = <String, String>{}.obs;

  void alternarClave() => claveVisible.toggle();

  Future<void> iniciarSesion() async {
    if (cargando.value) return;
    errorGeneral.value = null;
    errores.assignAll({
      'usuario': ?Validadores.requerido(usuario.text, 'Ingresa tu usuario.'),
      'clave': ?Validadores.requerido(clave.text, 'Ingresa tu clave.'),
    });
    if (errores.isNotEmpty) return;

    cargando.value = true;
    try {
      final perfil = await _repositorio.iniciarSesion(usuario.text, clave.text);
      _sesion.establecer(perfil);
      unawaited(Get.offAllNamed<void>(AppRoutes.consultas)); // la Future termina al cerrar esa ruta: no se espera
    } on UnauthorizedException catch (e) {
      // En el login, 401 = credenciales incorrectas (no "sesión expirada").
      errorGeneral.value = e.detalle ?? 'Usuario o clave incorrectos.';
    } on AppException catch (e) {
      errorGeneral.value = MensajesError.de(e);
    } finally {
      cargando.value = false;
    }
  }

  void irARegistro() => Get.toNamed<void>(AppRoutes.registro);

  @override
  void onClose() {
    usuario.dispose();
    clave.dispose();
    super.onClose();
  }
}
