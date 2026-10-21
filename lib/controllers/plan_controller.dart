import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../app/routes/app_routes.dart';
import '../core/config/app_config.dart';
import '../core/errors/app_exception.dart';
import '../data/models/plan.dart';
import '../data/repositories/planes_repository.dart';
import 'mensajes_error.dart';
import 'view_status.dart';

/// Plan y saldo de consultas. Es global: lo comparten "Mi plan" y el chat (saldo bajo el
/// cuadro de texto y aviso de consultas agotadas). Se vacía al cerrar sesión.
class PlanController extends GetxController {
  PlanController({required this._repositorio});

  final PlanesRepository _repositorio;

  final Rx<ViewStatus> estado = ViewStatus.loading.obs;
  final RxString mensajeError = ''.obs;
  final Rxn<EstadoPlan> plan = Rxn<EstadoPlan>();
  final RxList<PlanCatalogo> catalogo = <PlanCatalogo>[].obs;

  /// Carga saldo y catálogo para la pantalla "Mi plan".
  Future<void> cargar() async {
    if (plan.value == null) estado.value = ViewStatus.loading;
    try {
      plan.value = await _repositorio.estado();
      catalogo.assignAll(await _repositorio.catalogo());
      estado.value = ViewStatus.success;
    } on AppException catch (e) {
      _fallo(e);
    }
  }

  void _fallo(AppException e) {
    if (MensajesError.requiereLogin(e)) return;
    mensajeError.value = MensajesError.de(e);
    // Con un saldo ya cargado se sigue mostrando; el error solo ocupa la pantalla si no hay nada.
    if (plan.value == null) estado.value = ViewStatus.error;
  }

  /// Actualiza solo el saldo, en segundo plano (p. ej. tras cada respuesta del chat).
  Future<void> refrescarSaldo() async {
    try {
      plan.value = await _repositorio.estado();
    } on AppException {
      // el saldo es informativo: si falla, se conserva el último conocido
    }
  }

  /// Texto breve para el chat: "Te quedan 3 consultas gratis este mes", o null si no aplica.
  String? get resumenSaldo {
    final p = plan.value;
    if (p == null) return null;
    return switch (p.modo) {
      ModoPlan.pagado =>
        p.consultasPagadas == 1
            ? 'Te queda 1 consulta de tu plan'
            : 'Te quedan ${p.consultasPagadas} consultas de tu plan',
      ModoPlan.gratis =>
        p.gratisRestantes == 1
            ? 'Te queda 1 consulta gratis este mes'
            : 'Te quedan ${p.gratisRestantes} consultas gratis este mes',
      ModoPlan.sinSaldo => 'Sin consultas disponibles',
      ModoPlan.cortesia || ModoPlan.desconocido => null,
    };
  }

  String fechaCorta(DateTime fecha) => DateFormat.yMMMd('es').format(fecha.toLocal());

  Future<void> copiarEnlaceCompra() => Clipboard.setData(const ClipboardData(text: AppConfig.urlPlanes));

  void irAPlan() => Get.toNamed<void>(AppRoutes.plan);

  /// Al cerrar sesión: no queda el saldo de otra cuenta en memoria.
  Future<void> limpiar() async {
    plan.value = null;
    catalogo.clear();
    estado.value = ViewStatus.loading;
  }
}
