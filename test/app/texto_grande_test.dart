import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:lexiec/data/models/cita.dart';
import 'package:lexiec/data/models/conversacion.dart';
import 'package:lexiec/data/models/documento.dart';
import 'package:lexiec/data/models/mensaje.dart';
import 'package:lexiec/data/models/respuesta_chat.dart';
import 'package:lexiec/data/repositories/conversaciones_repository.dart';
import 'package:mocktail/mocktail.dart';

import '../helpers/app_prueba.dart';

/// Teléfono angosto (360 dp) con letra al 160 %: ninguna pantalla debe desbordarse.
void _telefonoAngostoLetraGrande(WidgetTester tester) {
  tester.view
    ..physicalSize = const Size(1080, 2340)
    ..devicePixelRatio = 3;
  tester.platformDispatcher.textScaleFactorTestValue = 1.6;
  addTearDown(tester.view.reset);
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
}

final _ahora = DateTime.now();
final _conv = Conversacion(
  id: 'c1',
  titulo: '¿Qué derechos tienen las personas adultas mayores según la Constitución?',
  creadaEn: _ahora,
  actualizadaEn: _ahora,
);

void main() {
  tearDown(Get.reset);

  testWidgets('login, registro y bienvenida', (tester) async {
    _telefonoAngostoLetraGrande(tester);
    await montarApp(tester, repositorioBase(bienvenidaVista: false));
    await tester.tap(find.text('Saltar'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Iniciar sesión'));
    await tester.pump(); // errores de campo visibles
    await tester.scrollUntilVisible(find.text('Crear cuenta'), 200, scrollable: find.byType(Scrollable).first);
    await tester.tap(find.text('Crear cuenta'));
    await tester.pumpAndSettle();
  });

  testWidgets('lista, chat con citas, sin información y respuesta en curso', (tester) async {
    _telefonoAngostoLetraGrande(tester);
    final conversaciones = conversacionesVacias();
    when(conversaciones.primeraPagina).thenAnswer((_) async => PaginaConversaciones(items: [_conv], hayMas: false));
    when(() => conversaciones.detalle('c1')).thenAnswer(
      (_) async => (
        ConversacionDetalle(
          conversacion: _conv,
          mensajes: [
            Mensaje(id: 1, rol: RolMensaje.usuario, contenido: _conv.titulo, creadoEn: _ahora),
            Mensaje(
              id: 2,
              rol: RolMensaje.asistente,
              contenido: 'Las personas adultas mayores recibirán atención prioritaria y especializada.',
              creadoEn: _ahora,
              citas: const [
                Cita(archivo: 'Codigo-Organico-Integral-Penal2025.pdf', pagina: 375, articulo: '10 bis', texto: '…'),
              ],
            ),
            Mensaje(id: 3, rol: RolMensaje.usuario, contenido: '¿y la multa?', creadoEn: _ahora),
            Mensaje(id: 4, rol: RolMensaje.asistente, contenido: RespuestaChat.textoSinInformacion, creadoEn: _ahora),
          ],
        ),
        false,
      ),
    );
    final chat = ChatRepositoryMock();
    when(
      () => chat.preguntar(any(), any(), cancelacion: any(named: 'cancelacion')),
    ).thenAnswer((_) => const Stream.empty());
    await montarApp(tester, repositorioBase(sesionGuardada: true), conversaciones: conversaciones, chat: chat);
    await tester.tap(find.text(_conv.titulo));
    await tester.pumpAndSettle();
  });

  testWidgets('mi cuenta, cambiar clave, eliminar cuenta y normas', (tester) async {
    _telefonoAngostoLetraGrande(tester);
    final documentos = DocumentosRepositoryMock();
    when(documentos.listar).thenAnswer(
      (_) async => [
        Documento(
          archivo: 'LOTAIP_6_Ley-Organica-de-Transporte-Terrestre-Transito-y-Seguridad-Vial-2021.pdf',
          paginas: 66,
          fragmentos: 330,
          indexadoEn: _ahora,
        ),
      ],
    );
    await montarApp(tester, repositorioBase(sesionGuardada: true), documentos: documentos);
    await abrirMiCuenta(tester);
    for (final destino in ['Cambiar clave', 'Eliminar mi cuenta', 'Normas disponibles']) {
      await tester.scrollUntilVisible(find.text(destino), 200, scrollable: find.byType(Scrollable).first);
      await tester.tap(find.text(destino));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();
    }
  });
}
