import 'package:flutter_test/flutter_test.dart';
import 'package:lexiec/data/models/cita.dart';
import 'package:lexiec/data/models/conversacion.dart';
import 'package:lexiec/data/models/documento.dart';
import 'package:lexiec/data/models/mensaje.dart';
import 'package:lexiec/data/models/perfil.dart';
import 'package:lexiec/data/models/respuesta_chat.dart';
import 'package:lexiec/data/models/tokens_sesion.dart';

// Ejemplos tomados de docs/GUIA_API_MOVIL.md (valores ficticios).
const _cita = {'archivo': 'constitucion.pdf', 'pagina': 18, 'articulo': '36', 'texto': 'Se considerarán…'};
const _fuente = {
  'archivo': 'constitucion.pdf',
  'pagina': 18,
  'articulo': '36',
  'relevancia': 0.9836,
  'extracto': 'Art. 36.-…',
};

void main() {
  test('TokensSesion desde el login', () {
    final t = TokensSesion.fromJson({
      'access_token': 'a',
      'token_type': 'bearer',
      'expires_in': 900,
      'refresh_token': 'r',
      'refresh_expires_in': 2592000,
    });
    expect(t.expiresIn, 900);
    expect(t.refreshToken, 'r');
  });

  test('Perfil con y sin nombre', () {
    final p = Perfil.fromJson({
      'usuario': 'maria.perez',
      'correo': null,
      'nombre': null,
      'creado_en': '2026-10-20T14:57:37.250518Z',
    });
    expect(p.nombreVisible, 'maria.perez');
    expect(p.creadoEn.isUtc, isTrue);
    expect(Perfil.fromJson({...p.toJson(), 'nombre': 'María Pérez'}).nombreVisible, 'María Pérez');
  });

  test('Cita: referencia con y sin artículo', () {
    expect(Cita.fromJson(_cita).referencia, 'Art. 36 · pág. 18');
    expect(Cita.fromJson({..._cita, 'articulo': null}).referencia, 'pág. 18');
  });

  test('ConversacionDetalle con mensajes, ida y vuelta por JSON', () {
    final json = {
      'id': '1fea31ae-9592-41ca-93bc-19cb2317935a',
      'titulo': '¿Qué derechos tienen las personas adultas mayores según la…',
      'creada_en': '2026-10-20T13:20:01.512Z',
      'actualizada_en': '2026-10-20T13:22:05.123Z',
      'mensajes': [
        {
          'id': 11,
          'rol': 'usuario',
          'contenido': '¿y a partir de qué edad?',
          'citas': [],
          'fuentes': [],
          'creado_en': '2026-10-20T13:21:00Z',
        },
        {
          'id': 12,
          'rol': 'asistente',
          'contenido': 'Sesenta y cinco años.',
          'citas': [_cita],
          'fuentes': [_fuente],
          'creado_en': '2026-10-20T13:22:05Z',
        },
      ],
    };
    final detalle = ConversacionDetalle.fromJson(json);
    expect(detalle.mensajes.first.esDelUsuario, isTrue);
    expect(detalle.mensajes.last.rol, RolMensaje.asistente);
    expect(detalle.mensajes.last.fuentes.single.relevancia, 0.9836);

    final copia = ConversacionDetalle.fromJson(detalle.toJson());
    expect(copia.conversacion.id, detalle.conversacion.id);
    expect(copia.mensajes.last.citas.single.referencia, 'Art. 36 · pág. 18');
  });

  test('RespuestaChat: con citas y "sin información"', () {
    final base = {
      'respuesta': 'Sí.',
      'citas': [_cita],
      'fuentes': [_fuente],
      'duracion_ms': 26242,
      'conversacion_id': 'c',
      'titulo': 't',
      'mensaje_id': 12,
    };
    expect(RespuestaChat.fromJson(base).sinInformacion, isFalse);
    final sinInfo = RespuestaChat.fromJson({
      ...base,
      'respuesta': RespuestaChat.textoSinInformacion,
      'citas': [],
      'fuentes': [],
    });
    expect(sinInfo.sinInformacion, isTrue);
  });

  test('Documento: nombre legible', () {
    final d = Documento.fromJson({
      'archivo': 'Codigo-Organico-Integral-Penal2025.pdf',
      'paginas': 387,
      'fragmentos': 1664,
      'indexado_en': '2026-10-20T14:25:09.418467Z',
    });
    expect(d.nombreVisible, 'Codigo Organico Integral Penal2025');
  });
}
