import 'dart:async';

import 'package:get/get.dart';

import '../app/routes/app_routes.dart';
import '../data/repositories/auth_repository.dart';
import 'sesion_controller.dart';

/// Decide la primera pantalla: bienvenida (1.ª vez), login o "Mis consultas".
class InicioController extends GetxController {
  InicioController({required this._repositorio, required this._sesion, Duration? pausaMarca})
    : _pausaMarca = pausaMarca ?? const Duration(milliseconds: 700);

  final AuthRepository _repositorio;
  final SesionController _sesion;
  final Duration _pausaMarca;

  @override
  void onReady() {
    super.onReady();
    decidir();
  }

  Future<void> decidir() async {
    final resultados = await Future.wait<Object?>([
      Future<void>.delayed(_pausaMarca), // la marca se ve sin parpadeo
      _destino(),
    ]);
    unawaited(Get.offAllNamed<void>(resultados[1]! as String)); // la Future termina al cerrar esa ruta: no se espera
  }

  Future<String> _destino() async {
    if (!await _repositorio.bienvenidaVista()) return AppRoutes.bienvenida;
    await _sesion.restaurar();
    return _sesion.autenticado ? AppRoutes.consultas : AppRoutes.login;
  }
}
