import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Mensaje breve en la parte inferior (usa el estilo del tema).
void mostrarAviso(String mensaje, {bool esError = false}) {
  final contexto = Get.context;
  if (contexto == null) return;
  final esquema = Theme.of(contexto).colorScheme;
  ScaffoldMessenger.maybeOf(contexto)
    ?..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text(mensaje, style: TextStyle(color: esError ? esquema.onErrorContainer : null)),
        backgroundColor: esError ? esquema.errorContainer : null,
      ),
    );
}
