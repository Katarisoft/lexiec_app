import 'package:flutter/material.dart';

import '../app/theme/app_spacing.dart';

/// Campo de texto con etiqueta, icono, ayuda y error (estilo del tema).
class CampoTexto extends StatelessWidget {
  const CampoTexto({
    super.key,
    required this.controlador,
    required this.etiqueta,
    this.icono,
    this.ayuda,
    this.error,
    this.oculto = false,
    this.sufijo,
    this.teclado,
    this.accion = TextInputAction.next,
    this.alEnviar,
    this.autocompletado,
    this.mayusculas = TextCapitalization.none,
  });

  final TextEditingController controlador;
  final String etiqueta;
  final IconData? icono;
  final String? ayuda;
  final String? error;
  final bool oculto;
  final Widget? sufijo;
  final TextInputType? teclado;
  final TextInputAction accion;
  final ValueChanged<String>? alEnviar;
  final Iterable<String>? autocompletado;
  final TextCapitalization mayusculas;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controlador,
      obscureText: oculto,
      enableSuggestions: !oculto,
      autocorrect: false,
      keyboardType: teclado,
      textInputAction: accion,
      textCapitalization: mayusculas,
      onSubmitted: alEnviar,
      autofillHints: autocompletado,
      decoration: InputDecoration(
        labelText: etiqueta,
        helperText: error == null ? ayuda : null,
        helperMaxLines: 2,
        errorText: error,
        errorMaxLines: 3,
        prefixIcon: icono == null ? null : Icon(icono),
        suffixIcon: sufijo,
      ),
    );
  }
}

/// Botón para mostrar/ocultar la clave (con etiqueta accesible).
class BotonVerClave extends StatelessWidget {
  const BotonVerClave({super.key, required this.visible, required this.alPresionar});

  final bool visible;
  final VoidCallback alPresionar;

  @override
  Widget build(BuildContext context) => IconButton(
    tooltip: visible ? 'Ocultar clave' : 'Mostrar clave',
    icon: Icon(visible ? Icons.visibility_off_outlined : Icons.visibility_outlined),
    onPressed: alPresionar,
  );
}

/// Botón principal que muestra un indicador mientras trabaja (y no admite toques repetidos).
class BotonCarga extends StatelessWidget {
  const BotonCarga({super.key, required this.texto, required this.cargando, required this.alPresionar});

  final String texto;
  final bool cargando;
  final VoidCallback alPresionar;

  @override
  Widget build(BuildContext context) {
    final esquema = Theme.of(context).colorScheme;
    return FilledButton(
      onPressed: cargando ? null : alPresionar,
      child: cargando
          ? SizedBox.square(
              dimension: 22,
              child: CircularProgressIndicator(strokeWidth: 2.4, color: esquema.onSurfaceVariant),
            )
          : Text(texto),
    );
  }
}

/// Aviso de error dentro de un formulario.
class AvisoError extends StatelessWidget {
  const AvisoError({super.key, required this.mensaje});

  final String mensaje;

  @override
  Widget build(BuildContext context) {
    final esquema = Theme.of(context).colorScheme;
    return Semantics(
      liveRegion: true,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(color: esquema.errorContainer, borderRadius: BorderRadius.circular(AppRadius.md)),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.error_outline, color: esquema.onErrorContainer),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(mensaje, style: TextStyle(color: esquema.onErrorContainer)),
            ),
          ],
        ),
      ),
    );
  }
}

/// Contenedor centrado y con ancho máximo para formularios.
class ContenidoFormulario extends StatelessWidget {
  const ContenidoFormulario({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.xl),
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: AppSizes.anchoMaximoContenido),
            child: AutofillGroup(
              child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: children),
            ),
          ),
        ),
      ),
    );
  }
}
