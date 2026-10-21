import 'package:get/get.dart';

import '../../screens/bienvenida/bienvenida_screen.dart';
import '../../screens/consultas/consultas_screen.dart';
import '../../screens/inicio/inicio_screen.dart';
import '../../screens/login/login_screen.dart';
import '../../screens/registro/registro_screen.dart';
import '../bindings/auth_bindings.dart';
import 'app_routes.dart';
import 'middlewares.dart';

/// Registro de páginas (GetPage) con sus bindings y protecciones.
abstract final class AppPages {
  static final List<GetPage<dynamic>> paginas = [
    GetPage(name: AppRoutes.inicio, page: () => const InicioScreen(), binding: InicioBinding()),
    GetPage(name: AppRoutes.bienvenida, page: () => const BienvenidaScreen(), binding: BienvenidaBinding()),
    GetPage(
      name: AppRoutes.login,
      page: () => const LoginScreen(),
      binding: LoginBinding(),
      middlewares: [SoloInvitadoMiddleware()],
    ),
    GetPage(
      name: AppRoutes.registro,
      page: () => const RegistroScreen(),
      binding: RegistroBinding(),
      middlewares: [SoloInvitadoMiddleware()],
      transition: Transition.rightToLeftWithFade,
    ),
    GetPage(name: AppRoutes.consultas, page: () => const ConsultasScreen(), middlewares: [SesionRequeridaMiddleware()]),
  ];
}
