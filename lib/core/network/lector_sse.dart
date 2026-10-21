import 'dart:convert';

/// Evento Server-Sent Events: `event: <nombre>` + una o más líneas `data: <texto>`.
class EventoSse {
  const EventoSse(this.evento, this.datos);

  final String evento;
  final String datos;
}

/// Convierte un flujo de bytes SSE en eventos (guía de la API, § 6.6).
/// Tolera trozos de red que cortan líneas o caracteres UTF-8 a la mitad.
Stream<EventoSse> leerSse(Stream<List<int>> bytes) async* {
  String? evento;
  final datos = <String>[];
  // bind (no transform): dio entrega Stream<Uint8List> y transform(utf8.decoder) falla por tipos en ejecución.
  await for (final linea in const LineSplitter().bind(utf8.decoder.bind(bytes))) {
    if (linea.isEmpty) {
      if (datos.isNotEmpty) yield EventoSse(evento ?? 'message', datos.join('\n'));
      evento = null;
      datos.clear();
      continue;
    }
    if (linea.startsWith(':')) continue; // comentario / keep-alive
    final separador = linea.indexOf(':');
    final campo = separador < 0 ? linea : linea.substring(0, separador);
    var valor = separador < 0 ? '' : linea.substring(separador + 1);
    if (valor.startsWith(' ')) valor = valor.substring(1);
    if (campo == 'event') {
      evento = valor;
    } else if (campo == 'data') {
      datos.add(valor);
    }
  }
  if (datos.isNotEmpty) yield EventoSse(evento ?? 'message', datos.join('\n')); // sin línea vacía final
}
