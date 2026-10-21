import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

import '../app/routes/app_routes.dart';
import '../data/repositories/auth_repository.dart';

/// Láminas de bienvenida (solo la primera vez).
class BienvenidaController extends GetxController {
  BienvenidaController({required this._repositorio});

  final AuthRepository _repositorio;
  final PageController paginas = PageController();
  final RxInt pagina = 0.obs;

  static const int totalPaginas = 3;

  bool get esUltima => pagina.value == totalPaginas - 1;

  void alCambiarPagina(int indice) => pagina.value = indice;

  Future<void> siguiente() async {
    if (esUltima) return terminar();
    await paginas.nextPage(duration: const Duration(milliseconds: 320), curve: Curves.easeOutCubic);
  }

  Future<void> terminar() async {
    await _repositorio.marcarBienvenidaVista();
    unawaited(Get.offAllNamed<void>(AppRoutes.login)); // la Future termina al cerrar esa ruta: no se espera
  }

  @override
  void onClose() {
    paginas.dispose();
    super.onClose();
  }
}
