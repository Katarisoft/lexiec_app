import 'package:dio/dio.dart';

/// Permite cancelar una petición en curso (p. ej. al salir del chat) sin que
/// los controladores dependan de `dio`.
class Cancelacion {
  final CancelToken token = CancelToken();

  bool get cancelada => token.isCancelled;

  void cancelar() {
    if (!token.isCancelled) token.cancel('cancelada por la persona');
  }
}
