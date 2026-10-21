import 'dart:async';

import 'package:get/get.dart';

import '../app/routes/app_routes.dart';
import '../core/errors/app_exception.dart';
import '../core/network/eventos_sesion.dart';
import '../data/models/perfil.dart';
import '../data/repositories/auth_repository.dart';
import '../widgets/avisos.dart';

enum EstadoSesion { verificando, autenticado, anonimo }

/// Estado de sesión compartido por toda la app (rutas protegidas, perfil, cierre).
class SesionController extends GetxController {
  SesionController({required this._repositorio, required this._eventos});

  final AuthRepository _repositorio;
  final EventosSesion _eventos;
  StreamSubscription<void>? _suscripcion;

  final Rx<EstadoSesion> estado = EstadoSesion.verificando.obs;
  final Rxn<Perfil> perfil = Rxn<Perfil>();

  bool get autenticado => estado.value == EstadoSesion.autenticado;

  @override
  void onInit() {
    super.onInit();
    _suscripcion = _eventos.expiraciones.listen((_) => _alExpirar());
  }

  @override
  void onClose() {
    _suscripcion?.cancel();
    super.onClose();
  }

  /// Al abrir la app: si hay tokens, valida la sesión (renovándola si hace falta).
  Future<void> restaurar() async {
    if (!await _repositorio.tieneSesionGuardada()) {
      estado.value = EstadoSesion.anonimo;
      return;
    }
    try {
      perfil.value = await _repositorio.perfil();
      estado.value = EstadoSesion.autenticado;
    } on UnauthorizedException {
      estado.value = EstadoSesion.anonimo; // el interceptor ya borró los tokens
    } on AppException {
      // Sin red u otro error temporal: se entra con la sesión guardada (historial local disponible).
      estado.value = EstadoSesion.autenticado;
    }
  }

  void establecer(Perfil nuevoPerfil) {
    perfil.value = nuevoPerfil;
    estado.value = EstadoSesion.autenticado;
  }

  Future<void> cerrarSesion() async {
    await _repositorio.cerrarSesion();
    _limpiar();
    unawaited(Get.offAllNamed<void>(AppRoutes.login)); // la Future termina al cerrar esa ruta: no se espera
  }

  void _alExpirar() {
    if (!autenticado) return;
    _limpiar();
    Get.offAllNamed<void>(AppRoutes.login);
    mostrarAviso('Tu sesión expiró. Inicia sesión de nuevo.');
  }

  void _limpiar() {
    perfil.value = null;
    estado.value = EstadoSesion.anonimo;
  }
}
