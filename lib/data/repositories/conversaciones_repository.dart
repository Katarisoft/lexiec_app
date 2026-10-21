import '../../core/errors/app_exception.dart';
import '../datasources/local_conversaciones_datasource.dart';
import '../datasources/remote_conversaciones_datasource.dart';
import '../models/conversacion.dart';

/// Página de conversaciones con su origen.
class PaginaConversaciones {
  const PaginaConversaciones({required this.items, required this.hayMas, this.desdeCache = false});

  final List<Conversacion> items;
  final bool hayMas;

  /// true si vino del historial local porque no había conexión.
  final bool desdeCache;
}

/// Combina la API (fuente de verdad) con el historial local cifrado (sin conexión).
class ConversacionesRepository {
  ConversacionesRepository({required this._remoto, required this._local});

  final RemoteConversacionesDatasource _remoto;
  final LocalConversacionesDatasource _local;

  static const int tamanoPagina = 20;

  Future<void> prepararPara(String usuario) => _local.asignarUsuario(usuario);

  /// Lo guardado localmente, para mostrar algo al instante mientras llega la red.
  Future<List<Conversacion>?> historialLocal() => _local.leerLista();

  /// Primera página desde la API (y la guarda). Sin conexión, devuelve el historial local.
  Future<PaginaConversaciones> primeraPagina() async {
    try {
      final items = await _remoto.listar(limite: tamanoPagina);
      await _local.guardarLista(items);
      return PaginaConversaciones(items: items, hayMas: items.length == tamanoPagina);
    } on AppException catch (e) {
      if (!_esFaltaDeConexion(e)) rethrow;
      final guardadas = await _local.leerLista();
      if (guardadas == null) rethrow;
      return PaginaConversaciones(items: guardadas, hayMas: false, desdeCache: true);
    }
  }

  /// Páginas siguientes (solo en línea); se agregan al historial local.
  Future<PaginaConversaciones> siguientePagina(List<Conversacion> actuales) async {
    final nuevas = await _remoto.listar(limite: tamanoPagina, desplazamiento: actuales.length);
    final ids = actuales.map((c) => c.id).toSet();
    final todas = [...actuales, ...nuevas.where((c) => !ids.contains(c.id))];
    await _local.guardarLista(todas);
    return PaginaConversaciones(items: todas, hayMas: nuevas.length == tamanoPagina);
  }

  Future<Conversacion> crear() async {
    final nueva = await _remoto.crear();
    final lista = await _local.leerLista() ?? const [];
    await _local.guardarLista([nueva, ...lista]);
    return nueva;
  }

  /// Detalle desde la API (y lo guarda); sin conexión, el guardado. Devuelve (detalle, desdeCache).
  Future<(ConversacionDetalle, bool)> detalle(String id) async {
    try {
      final detalle = await _remoto.detalle(id);
      await _local.guardarDetalle(detalle);
      return (detalle, false);
    } on NotFoundException {
      await _local.eliminar(id); // eliminada en otro dispositivo
      rethrow;
    } on AppException catch (e) {
      if (!_esFaltaDeConexion(e)) rethrow;
      final guardado = await _local.leerDetalle(id);
      if (guardado == null) rethrow;
      return (guardado, true);
    }
  }

  /// Elimina en el servidor y en el historial local. Si ya no existía (404), se da por eliminada.
  Future<void> eliminar(String id) async {
    try {
      await _remoto.eliminar(id);
    } on NotFoundException {
      // ya no existe en el servidor
    }
    await _local.eliminar(id);
  }

  Future<void> limpiarHistorialLocal() => _local.vaciar();

  static bool _esFaltaDeConexion(AppException e) => e is NetworkException || e is RequestTimeoutException;
}
