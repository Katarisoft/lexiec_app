import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

import '../app/routes/app_routes.dart';
import '../core/errors/app_exception.dart';
import '../data/repositories/auth_repository.dart';
import '../widgets/avisos.dart';
import 'mensajes_error.dart';
import 'sesion_controller.dart';
import 'validadores.dart';

class RegistroController extends GetxController {
  RegistroController({required this._repositorio, required this._sesion});

  final AuthRepository _repositorio;
  final SesionController _sesion;

  // Las claves coinciden con los nombres de campo de la API (errores 422).
  final TextEditingController usuario = TextEditingController();
  final TextEditingController clave = TextEditingController();
  final TextEditingController confirmacion = TextEditingController();
  final TextEditingController codigo = TextEditingController();
  final TextEditingController nombre = TextEditingController();
  final TextEditingController correo = TextEditingController();

  final RxBool cargando = false.obs;
  final RxBool claveVisible = false.obs;
  final RxnString errorGeneral = RxnString();
  final RxMap<String, String> errores = <String, String>{}.obs;

  void alternarClave() => claveVisible.toggle();

  Map<String, String> _validar() => {
    'usuario': ?Validadores.usuario(usuario.text),
    'clave': ?Validadores.claveNueva(clave.text, usuario: usuario.text),
    'confirmacion': ?Validadores.confirmacion(confirmacion.text, clave.text),
    'codigo_invitacion': ?Validadores.requerido(codigo.text, 'Ingresa el código de invitación.'),
    'nombre': ?Validadores.nombreOpcional(nombre.text),
    'correo': ?Validadores.correoOpcional(correo.text),
  };

  Future<void> registrar() async {
    if (cargando.value) return;
    errorGeneral.value = null;
    errores.assignAll(_validar());
    if (errores.isNotEmpty) return;

    cargando.value = true;
    try {
      final perfil = await _repositorio.registrar(
        usuario: usuario.text,
        clave: clave.text,
        codigoInvitacion: codigo.text,
        correo: Validadores.opcional(correo.text),
        nombre: Validadores.opcional(nombre.text),
      );
      _sesion.establecer(perfil);
      unawaited(Get.offAllNamed<void>(AppRoutes.consultas)); // la Future termina al cerrar esa ruta: no se espera
      mostrarAviso('¡Cuenta creada! Ya puedes hacer tu primera consulta.');
    } on ConflictException catch (e) {
      final campo = (e.detalle ?? '').toLowerCase().contains('correo') ? 'correo' : 'usuario';
      errores[campo] = MensajesError.de(e);
    } on ForbiddenException catch (e) {
      errores['codigo_invitacion'] = MensajesError.de(e);
    } on ValidationException catch (e) {
      final generales = Map.of(e.campos)..remove(ValidationException.general);
      errores.assignAll(generales);
      errorGeneral.value = e.campos[ValidationException.general];
    } on AppException catch (e) {
      errorGeneral.value = MensajesError.de(e);
    } finally {
      cargando.value = false;
    }
  }

  @override
  void onClose() {
    for (final c in [usuario, clave, confirmacion, codigo, nombre, correo]) {
      c.dispose();
    }
    super.onClose();
  }
}
