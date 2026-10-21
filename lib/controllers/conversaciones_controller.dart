import 'dart:async';

import 'package:get/get.dart';

import '../app/routes/app_routes.dart';
import '../core/errors/app_exception.dart';
import '../data/models/conversacion.dart';
import '../data/repositories/conversaciones_repository.dart';
import '../widgets/avisos.dart';
import 'mensajes_error.dart';
import 'sesion_controller.dart';
import 'view_status.dart';

/// "Mis consultas": estado compartido entre la lista y el detalle de una consulta.
class ConversacionesController extends GetxController {
  ConversacionesController({required this._repositorio, required this._sesion, Duration? esperaDeshacer})
    : _esperaDeshacer = esperaDeshacer ?? const Duration(seconds: 4);

  final ConversacionesRepository _repositorio;
  final SesionController _sesion;
  final Duration _esperaDeshacer;

  final RxList<Conversacion> conversaciones = <Conversacion>[].obs;
  final Rx<ViewStatus> estado = ViewStatus.loading.obs;
  final RxString mensajeError = ''.obs;
  final RxBool sinConexion = false.obs;
  final RxBool hayMas = false.obs;
  final RxBool cargandoMas = false.obs;
  final RxBool creando = false.obs;
  final RxString filtro = ''.obs;

  /// Eliminaciones pendientes de confirmar (se pueden deshacer durante unos segundos).
  final Map<String, Timer> _pendientes = {};

  /// Conversaciones que coinciden con la búsqueda (sin distinguir tildes ni mayúsculas).
  List<Conversacion> get visibles {
    final texto = _normalizar(filtro.value);
    if (texto.isEmpty) return conversaciones;
    return conversaciones.where((c) => _normalizar(c.titulo).contains(texto)).toList();
  }

  @override
  void onInit() {
    super.onInit();
    cargar();
  }

  /// Carga inicial: muestra al instante el historial local y luego lo actualiza desde la API.
  Future<void> cargar() async {
    final usuario = _sesion.perfil.value?.usuario;
    if (usuario != null) await _repositorio.prepararPara(usuario);
    final locales = await _repositorio.historialLocal();
    if (locales != null && locales.isNotEmpty) {
      conversaciones.assignAll(locales);
      estado.value = ViewStatus.success;
    } else {
      estado.value = ViewStatus.loading;
    }
    await refrescar();
  }

  /// Recarga la primera página (también "deslizar para actualizar").
  Future<void> refrescar() async {
    try {
      final pagina = await _repositorio.primeraPagina();
      conversaciones.assignAll(pagina.items);
      hayMas.value = pagina.hayMas;
      sinConexion.value = pagina.desdeCache;
      estado.value = pagina.items.isEmpty ? ViewStatus.empty : ViewStatus.success;
    } on AppException catch (e) {
      if (MensajesError.requiereLogin(e)) return; // la sesión expiró: el SesionController lleva al login
      mensajeError.value = MensajesError.de(e);
      if (conversaciones.isEmpty) {
        estado.value = ViewStatus.error;
      } else {
        mostrarAviso(mensajeError.value, esError: true); // se conserva lo que ya se ve
      }
    }
  }

  Future<void> cargarMas() async {
    if (!hayMas.value || cargandoMas.value || sinConexion.value) return;
    cargandoMas.value = true;
    try {
      final pagina = await _repositorio.siguientePagina(conversaciones);
      conversaciones.assignAll(pagina.items);
      hayMas.value = pagina.hayMas;
    } on AppException catch (e) {
      mostrarAviso(MensajesError.de(e), esError: true);
    } finally {
      cargandoMas.value = false;
    }
  }

  Future<void> nuevaConsulta() async {
    if (creando.value) return;
    creando.value = true;
    try {
      final nueva = await _repositorio.crear();
      conversaciones.insert(0, nueva);
      estado.value = ViewStatus.success;
      unawaited(abrir(nueva));
    } on AppException catch (e) {
      mostrarAviso(MensajesError.de(e), esError: true);
    } finally {
      creando.value = false;
    }
  }

  Future<void> abrir(Conversacion conversacion) async {
    await Get.toNamed<void>(AppRoutes.consulta(conversacion.id));
  }

  /// Quita la consulta de la lista al instante y la elimina en el servidor tras unos segundos,
  /// salvo que la persona pulse "Deshacer".
  void eliminarConDeshacer(Conversacion conversacion) {
    final indice = conversaciones.indexWhere((c) => c.id == conversacion.id);
    if (indice < 0) return;
    conversaciones.removeAt(indice);
    _actualizarEstadoTrasCambio();

    _pendientes[conversacion.id] = Timer(_esperaDeshacer, () => _confirmarEliminacion(conversacion, indice));
    mostrarAviso(
      'Consulta eliminada',
      accion: 'Deshacer',
      alAccion: () => _deshacer(conversacion, indice),
      duracion: _esperaDeshacer,
    );
  }

  /// Elimina sin opción de deshacer (desde el detalle, tras confirmar).
  Future<bool> eliminarAhora(Conversacion conversacion) async {
    try {
      await _repositorio.eliminar(conversacion.id);
      conversaciones.removeWhere((c) => c.id == conversacion.id);
      _actualizarEstadoTrasCambio();
      return true;
    } on AppException catch (e) {
      mostrarAviso(MensajesError.de(e), esError: true);
      return false;
    }
  }

  /// El detalle informa cambios (p. ej. título generado tras la primera pregunta).
  void actualizar(Conversacion conversacion) {
    final i = conversaciones.indexWhere((c) => c.id == conversacion.id);
    if (i >= 0) conversaciones[i] = conversacion;
  }

  /// Tras una nueva pregunta, la consulta pasa a ser la más reciente.
  void subirAlInicio(Conversacion conversacion) {
    conversaciones
      ..removeWhere((c) => c.id == conversacion.id)
      ..insert(0, conversacion);
    _actualizarEstadoTrasCambio();
  }

  void _deshacer(Conversacion conversacion, int indice) {
    _pendientes.remove(conversacion.id)?.cancel();
    conversaciones.insert(indice.clamp(0, conversaciones.length), conversacion);
    _actualizarEstadoTrasCambio();
  }

  Future<void> _confirmarEliminacion(Conversacion conversacion, int indice) async {
    _pendientes.remove(conversacion.id);
    try {
      await _repositorio.eliminar(conversacion.id);
    } on AppException catch (e) {
      conversaciones.insert(indice.clamp(0, conversaciones.length), conversacion); // se restaura
      _actualizarEstadoTrasCambio();
      mostrarAviso('No se pudo eliminar. ${MensajesError.de(e)}', esError: true);
    }
  }

  void _actualizarEstadoTrasCambio() => estado.value = conversaciones.isEmpty ? ViewStatus.empty : ViewStatus.success;

  @override
  void onClose() {
    // Al salir (p. ej. cerrar sesión) las eliminaciones pendientes se ejecutan ya.
    for (final timer in _pendientes.values) {
      if (timer.isActive) timer.cancel();
    }
    _pendientes.clear();
    super.onClose();
  }

  static String _normalizar(String texto) {
    const conTilde = 'áéíóúüñ';
    const sinTilde = 'aeiouun';
    var t = texto.toLowerCase().trim();
    for (var i = 0; i < conTilde.length; i++) {
      t = t.replaceAll(conTilde[i], sinTilde[i]);
    }
    return t;
  }
}
