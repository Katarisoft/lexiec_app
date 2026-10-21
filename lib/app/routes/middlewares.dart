import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

import '../../controllers/sesion_controller.dart';
import 'app_routes.dart';

/// Rutas protegidas: sin sesión, redirige al login.
class SesionRequeridaMiddleware extends GetMiddleware {
  @override
  RouteSettings? redirect(String? route) =>
      Get.find<SesionController>().autenticado ? null : const RouteSettings(name: AppRoutes.login);
}

/// Login y registro: con sesión activa, lleva directo a "Mis consultas".
class SoloInvitadoMiddleware extends GetMiddleware {
  @override
  RouteSettings? redirect(String? route) =>
      Get.find<SesionController>().autenticado ? const RouteSettings(name: AppRoutes.consultas) : null;
}
