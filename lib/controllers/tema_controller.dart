import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../data/repositories/preferencias_repository.dart';

/// Tema de la app (sistema, claro u oscuro), guardado en el dispositivo.
class TemaController extends GetxController {
  TemaController({required this._preferencias});

  final PreferenciasRepository _preferencias;
  final Rx<ThemeMode> modo = ThemeMode.system.obs;

  @override
  void onInit() {
    super.onInit();
    _cargar();
  }

  Future<void> _cargar() async {
    modo.value = await _preferencias.tema();
    Get.changeThemeMode(modo.value);
  }

  Future<void> cambiar(ThemeMode nuevo) async {
    modo.value = nuevo;
    Get.changeThemeMode(nuevo);
    await _preferencias.guardarTema(nuevo);
  }
}
