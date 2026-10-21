import 'package:get/get.dart';

import '../../core/network/almacen_tokens.dart';
import '../../core/network/api_client.dart';
import '../../core/network/eventos_sesion.dart';
import '../../data/datasources/local_tokens_datasource.dart';

/// Dependencias globales (viven toda la app).
class InicialBinding extends Bindings {
  @override
  void dependencies() {
    Get.put<AlmacenTokens>(LocalTokensDatasource(), permanent: true);
    Get.put<EventosSesion>(EventosSesion(), permanent: true);
    Get.put<ApiClient>(
      ApiClient(almacen: Get.find<AlmacenTokens>(), eventos: Get.find<EventosSesion>()),
      permanent: true,
    );
  }
}
