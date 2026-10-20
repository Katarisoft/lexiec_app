import 'package:get/get.dart';

import '../../screens/inicio/inicio_screen.dart';
import 'app_routes.dart';

/// Registro de páginas (GetPage) con sus bindings.
abstract final class AppPages {
  static final List<GetPage<dynamic>> paginas = [GetPage(name: AppRoutes.inicio, page: () => const InicioScreen())];
}
