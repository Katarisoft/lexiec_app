import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

import '../core/errors/app_exception.dart';
import '../core/network/cancelacion.dart';
import '../data/models/conversacion.dart';
import '../data/models/evento_chat.dart';
import '../data/models/mensaje.dart';
import '../data/models/respuesta_chat.dart';
import '../data/repositories/chat_repository.dart';
import '../data/repositories/conversaciones_repository.dart';
import 'conversaciones_controller.dart';
import 'mensajes_error.dart';
import 'view_status.dart';

/// Chat de una consulta: historial, nueva pregunta y respuesta en streaming.
class ConsultaController extends GetxController {
  ConsultaController({required this._repositorio, required this._chat, required this._lista, required this.id});

  final ConversacionesRepository _repositorio;
  final ChatRepository _chat;

  /// Controlador compartido de la lista (para reflejar cambios en "Mis consultas").
  final ConversacionesController _lista;
  final String id;

  static const int minimoCaracteres = 3;
  static const int maximoCaracteres = 1000;

  /// Ideas para empezar una consulta nueva.
  static const List<String> sugerencias = [
    '¿Qué derechos tienen las personas adultas mayores?',
    '¿Se puede conducir después de beber alcohol?',
    '¿Qué es la calumnia según el COIP?',
    '¿Qué dice la Constitución sobre la educación?',
  ];

  final Rx<ViewStatus> estado = ViewStatus.loading.obs;
  final RxString mensajeError = ''.obs;
  final Rxn<Conversacion> conversacion = Rxn<Conversacion>();
  final RxList<Mensaje> mensajes = <Mensaje>[].obs;
  final RxBool sinConexion = false.obs;

  final TextEditingController pregunta = TextEditingController();
  final RxBool enviando = false.obs;

  /// Texto provisional mientras el asistente escribe (se reemplaza por la respuesta verificada).
  final RxString provisional = ''.obs;
  final RxnString errorEnvio = RxnString();

  /// Segundos para poder volver a preguntar (429 / 503 con Retry-After).
  final RxInt esperaSegundos = 0.obs;

  Cancelacion? _cancelacion;
  Timer? _cuentaRegresiva;

  String get titulo => conversacion.value?.titulo ?? 'Consulta';

  bool get puedeEnviar =>
      !enviando.value &&
      esperaSegundos.value == 0 &&
      (estado.value == ViewStatus.success || estado.value == ViewStatus.empty);

  @override
  void onInit() {
    super.onInit();
    conversacion.value = _lista.conversaciones.firstWhereOrNull((c) => c.id == id);
    cargar();
  }

  Future<void> cargar() async {
    estado.value = ViewStatus.loading;
    try {
      final (detalle, desdeCache) = await _repositorio.detalle(id);
      conversacion.value = detalle.conversacion;
      mensajes.assignAll(detalle.mensajes);
      sinConexion.value = desdeCache;
      _lista.actualizar(detalle.conversacion);
      estado.value = detalle.mensajes.isEmpty ? ViewStatus.empty : ViewStatus.success;
    } on AppException catch (e) {
      if (MensajesError.requiereLogin(e)) return;
      mensajeError.value = e is NotFoundException
          ? 'Esta consulta ya no existe. Puede que se haya eliminado en otro dispositivo.'
          : MensajesError.de(e);
      estado.value = ViewStatus.error;
    }
  }

  /// Envía la pregunta escrita (o una sugerencia) y recibe la respuesta en streaming.
  Future<void> enviar([String? sugerencia]) async {
    final texto = (sugerencia ?? pregunta.text).trim();
    if (texto.length < minimoCaracteres) {
      errorEnvio.value = 'Escribe al menos $minimoCaracteres caracteres.';
      return;
    }
    if (texto.length > maximoCaracteres) {
      errorEnvio.value = 'La pregunta puede tener como máximo $maximoCaracteres caracteres.';
      return;
    }
    if (!puedeEnviar) return;

    errorEnvio.value = null;
    pregunta.clear();
    final propia = Mensaje(
      id: -DateTime.now().microsecondsSinceEpoch, // provisional: el servidor asigna el definitivo
      rol: RolMensaje.usuario,
      contenido: texto,
      creadoEn: DateTime.now(),
    );
    mensajes.add(propia);
    estado.value = ViewStatus.success;
    enviando.value = true;
    provisional.value = '';
    _cancelacion = Cancelacion();

    var terminada = false;
    try {
      await for (final evento in _chat.preguntar(id, texto, cancelacion: _cancelacion)) {
        switch (evento) {
          case EventoDelta(:final texto):
            provisional.value += texto;
          case EventoFinal(:final respuesta):
            terminada = true;
            _aplicarRespuesta(respuesta);
          case EventoError(:final detalle, :final codigo):
            terminada = true;
            _revertir(propia, detalle, espera: codigo == 'ocupado' ? const Duration(seconds: 10) : null);
        }
      }
      if (!terminada && !(_cancelacion?.cancelada ?? false)) {
        _revertir(propia, 'La respuesta se interrumpió. Intenta de nuevo.');
      }
    } on CancelledException {
      // La persona salió del chat: no hay nada que mostrar.
    } on AppException catch (e) {
      if (MensajesError.requiereLogin(e)) return;
      final espera = switch (e) {
        RateLimitException(:final reintentarEn) => reintentarEn ?? const Duration(seconds: 30),
        ServiceBusyException(:final reintentarEn) => reintentarEn ?? const Duration(seconds: 10),
        _ => null,
      };
      _revertir(propia, MensajesError.de(e), espera: espera);
    } finally {
      enviando.value = false;
      provisional.value = '';
      _cancelacion = null;
    }
  }

  /// Reemplaza el texto provisional por la respuesta verificada (con sus citas).
  void _aplicarRespuesta(RespuestaChat respuesta) {
    mensajes.add(
      Mensaje(
        id: respuesta.mensajeId,
        rol: RolMensaje.asistente,
        contenido: respuesta.respuesta,
        citas: respuesta.citas,
        fuentes: respuesta.fuentes,
        creadoEn: DateTime.now(),
      ),
    );
    final actual = conversacion.value;
    if (actual != null) {
      final actualizada = actual.copyWith(titulo: respuesta.titulo, actualizadaEn: DateTime.now());
      conversacion.value = actualizada;
      _lista.subirAlInicio(actualizada);
      unawaited(
        _chat
            .guardarHistorial(ConversacionDetalle(conversacion: actualizada, mensajes: List.of(mensajes)))
            .catchError((Object _) {}), // el historial local es una copia: un fallo aquí no afecta al chat
      );
    }
  }

  /// El servidor no guardó el turno: se quita la pregunta y vuelve al cuadro de texto para reintentar.
  void _revertir(Mensaje propia, String motivo, {Duration? espera}) {
    mensajes.remove(propia);
    if (pregunta.text.isEmpty) pregunta.text = propia.contenido;
    errorEnvio.value = motivo;
    if (mensajes.isEmpty) estado.value = ViewStatus.empty;
    if (espera != null) _iniciarEspera(espera);
  }

  void _iniciarEspera(Duration espera) {
    _cuentaRegresiva?.cancel();
    esperaSegundos.value = espera.inSeconds.clamp(1, 600);
    _cuentaRegresiva = Timer.periodic(const Duration(seconds: 1), (t) {
      esperaSegundos.value--;
      if (esperaSegundos.value <= 0) {
        esperaSegundos.value = 0;
        t.cancel();
      }
    });
  }

  /// Elimina la consulta (tras confirmar en la pantalla) y vuelve a la lista.
  Future<void> eliminar() async {
    final actual = conversacion.value;
    if (actual == null) return;
    if (await _lista.eliminarAhora(actual)) Get.back<void>();
  }

  @override
  void onClose() {
    _cancelacion?.cancelar(); // corta la respuesta en curso al salir
    _cuentaRegresiva?.cancel();
    pregunta.dispose();
    super.onClose();
  }
}
