import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:lexiec/core/errors/app_exception.dart';
import 'package:lexiec/data/models/cita.dart';
import 'package:lexiec/data/models/conversacion.dart';
import 'package:lexiec/data/models/evento_chat.dart';
import 'package:lexiec/data/models/mensaje.dart';
import 'package:lexiec/data/models/respuesta_chat.dart';
import 'package:lexiec/data/repositories/conversaciones_repository.dart';
import 'package:lexiec/screens/consulta/consulta_screen.dart';
import 'package:mocktail/mocktail.dart';

import '../helpers/app_prueba.dart';

final _ahora = DateTime.now();
final _conv = Conversacion(id: 'c1', titulo: 'Nueva conversación', creadaEn: _ahora, actualizadaEn: _ahora);

const _respuesta = RespuestaChat(
  respuesta: 'No se podrá conducir si se ha ingerido alcohol en niveles superiores a los permitidos.',
  citas: [Cita(archivo: 'ley_transito.pdf', pagina: 41, articulo: '182', texto: 'No se podrá conducir…')],
  fuentes: [],
  duracionMs: 39410,
  conversacionId: 'c1',
  titulo: '¿Se puede conducir después de beber alcohol?',
  mensajeId: 16,
);

class _Montaje {
  _Montaje(this.chat, this.conversaciones, this.flujo);

  final ChatRepositoryMock chat;
  final ConversacionesRepositoryMock conversaciones;
  StreamController<EventoChat> flujo;
}

Future<_Montaje> _abrirChat(WidgetTester tester, {List<Mensaje> mensajes = const []}) async {
  final conversaciones = conversacionesVacias();
  when(conversaciones.primeraPagina).thenAnswer((_) async => PaginaConversaciones(items: [_conv], hayMas: false));
  when(
    () => conversaciones.detalle('c1'),
  ).thenAnswer((_) async => (ConversacionDetalle(conversacion: _conv, mensajes: mensajes), false));
  final chat = ChatRepositoryMock();
  final montaje = _Montaje(chat, conversaciones, StreamController<EventoChat>());
  when(
    () => chat.preguntar(any(), any(), cancelacion: any(named: 'cancelacion')),
  ).thenAnswer((_) => montaje.flujo.stream);
  when(() => chat.guardarHistorial(any())).thenAnswer((_) async {});
  await montarApp(tester, repositorioBase(sesionGuardada: true), conversaciones: conversaciones, chat: chat);
  await tester.tap(find.text('Nueva conversación'));
  await tester.pumpAndSettle();
  expect(find.byType(ConsultaScreen), findsOneWidget);
  return montaje;
}

Future<void> _preguntar(WidgetTester tester, String texto) async {
  await tester.enterText(find.widgetWithText(TextField, 'Escribe tu pregunta'), texto);
  await tester.pump();
  await tester.tap(find.byTooltip('Enviar pregunta'));
  await tester.pump();
}

void main() {
  setUpAll(() => registerFallbackValue(ConversacionDetalle(conversacion: _conv, mensajes: const [])));
  tearDown(Get.reset);

  testWidgets('consulta nueva: muestra sugerencias y tocar una la envía', (tester) async {
    final m = await _abrirChat(tester);
    expect(find.text('¿Qué quieres consultar?'), findsOneWidget);
    await tester.tap(find.text('¿Se puede conducir después de beber alcohol?'));
    await tester.pump();
    verify(
      () => m.chat.preguntar(
        'c1',
        '¿Se puede conducir después de beber alcohol?',
        cancelacion: any(named: 'cancelacion'),
      ),
    ).called(1);
    await m.flujo.close();
    await tester.pumpAndSettle();
  });

  testWidgets('streaming: texto provisional que el final REEMPLAZA por la respuesta verificada', (tester) async {
    final m = await _abrirChat(tester);
    await _preguntar(tester, '¿Se puede conducir después de beber alcohol?');
    expect(find.text('¿Se puede conducir después de beber alcohol?'), findsWidgets); // burbuja propia
    expect(find.text('Buscando en las normas…'), findsOneWidget);

    m.flujo.add(const EventoDelta('Se podrá conducir '));
    await tester.pump();
    expect(find.text('Se podrá conducir '), findsOneWidget);
    expect(find.text('Verificando las fuentes…'), findsOneWidget);

    m.flujo.add(const EventoFinal(_respuesta));
    await m.flujo.close();
    await tester.pumpAndSettle();
    expect(find.text('Se podrá conducir '), findsNothing); // el provisional desaparece
    expect(find.text(_respuesta.respuesta), findsOneWidget);
    expect(find.text('Art. 182 · pág. 41'), findsOneWidget);
    expect(find.text('¿Se puede conducir después de beber alcohol?'), findsWidgets); // título actualizado
    verify(() => m.chat.guardarHistorial(any())).called(1);
  });

  testWidgets('evento error "ocupado": la pregunta vuelve al cuadro y se espera para reenviar', (tester) async {
    final m = await _abrirChat(tester);
    await _preguntar(tester, '¿Qué es la calumnia?');
    m.flujo.add(const EventoError(detalle: 'El servicio está ocupado.', codigo: 'ocupado'));
    await m.flujo.close();
    await tester.pump();
    await tester.pump();
    expect(find.textContaining('El servicio está ocupado.'), findsOneWidget);
    expect(find.textContaining('(10 s)'), findsOneWidget);
    expect(tester.widget<TextField>(find.byType(TextField)).controller!.text, '¿Qué es la calumnia?');
    final boton = tester.widget<IconButton>(find.widgetWithIcon(IconButton, Icons.send_rounded));
    expect(boton.onPressed, isNull);
    await tester.pump(const Duration(seconds: 11));
    expect(tester.widget<IconButton>(find.widgetWithIcon(IconButton, Icons.send_rounded)).onPressed, isNotNull);
  });

  testWidgets('429 antes del streaming: muestra el motivo y la cuenta regresiva', (tester) async {
    final m = await _abrirChat(tester);
    when(
      () => m.chat.preguntar(any(), any(), cancelacion: any(named: 'cancelacion')),
    ).thenAnswer((_) => Stream.error(const RateLimitException(reintentarEn: Duration(seconds: 30))));
    await _preguntar(tester, '¿Qué es la calumnia?');
    await tester.pump();
    expect(find.textContaining('muchas preguntas seguidas'), findsOneWidget);
    expect(find.textContaining('(30 s)'), findsOneWidget);
    await tester.pump(const Duration(seconds: 31));
  });

  testWidgets('sin conexión: mensaje claro y la pregunta no se pierde', (tester) async {
    final m = await _abrirChat(tester);
    when(
      () => m.chat.preguntar(any(), any(), cancelacion: any(named: 'cancelacion')),
    ).thenAnswer((_) => Stream.error(const NetworkException()));
    await _preguntar(tester, '¿Qué es la calumnia?');
    await tester.pump();
    expect(find.textContaining('Sin conexión'), findsOneWidget);
    expect(tester.widget<TextField>(find.byType(TextField)).controller!.text, '¿Qué es la calumnia?');
  });

  testWidgets('pregunta demasiado corta: avisa sin llamar a la API', (tester) async {
    final m = await _abrirChat(tester);
    await _preguntar(tester, 'ab');
    expect(find.text('Escribe al menos 3 caracteres.'), findsOneWidget);
    verifyNever(() => m.chat.preguntar(any(), any(), cancelacion: any(named: 'cancelacion')));
  });

  testWidgets('salir del chat cancela la respuesta en curso', (tester) async {
    final m = await _abrirChat(tester);
    await _preguntar(tester, '¿Qué es la calumnia?');
    final cancelacion = verify(
      () => m.chat.preguntar(any(), any(), cancelacion: captureAny(named: 'cancelacion')),
    ).captured.single;
    await tester.tap(find.byType(BackButton)); // pageBack() busca el texto en inglés
    await tester.pumpAndSettle();
    expect((cancelacion as dynamic).cancelada, isTrue);
    await m.flujo.close();
  });
}
