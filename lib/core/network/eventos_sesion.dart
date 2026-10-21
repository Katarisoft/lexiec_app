import 'dart:async';

/// Avisa que la sesión expiró sin posibilidad de renovarla (refresh token
/// inválido). El controlador de sesión escucha y lleva al login.
class EventosSesion {
  final StreamController<void> _expiraciones = StreamController<void>.broadcast();

  Stream<void> get expiraciones => _expiraciones.stream;

  void notificarExpiracion() => _expiraciones.add(null);

  Future<void> cerrar() => _expiraciones.close();
}
