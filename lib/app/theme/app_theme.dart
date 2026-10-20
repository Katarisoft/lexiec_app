import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_spacing.dart';

/// Temas claro y oscuro (Material 3). Las pantallas leen colores y estilos con
/// `Theme.of(context)`; nunca usan colores literales.
abstract final class AppTheme {
  static ThemeData claro() => _construir(
    ColorScheme.fromSeed(seedColor: AppColors.marino).copyWith(
      primary: AppColors.marino,
      secondary: AppColors.ambar,
      onSecondary: AppColors.sobreAmbar,
      surface: AppColors.superficieClara,
    ),
    AppColors.fondoClaro,
  );

  static ThemeData oscuro() => _construir(
    ColorScheme.fromSeed(seedColor: AppColors.marino, brightness: Brightness.dark).copyWith(
      primary: AppColors.marinoClaro,
      secondary: AppColors.ambar,
      onSecondary: AppColors.sobreAmbar,
      surface: AppColors.superficieOscura,
    ),
    AppColors.fondoOscuro,
  );

  static ThemeData _construir(ColorScheme esquema, Color fondo) {
    final base = ThemeData(useMaterial3: true, colorScheme: esquema);
    final texto = base.textTheme.copyWith(
      headlineMedium: base.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w700, letterSpacing: -0.5),
      headlineSmall: base.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700, letterSpacing: -0.3),
      titleLarge: base.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
      titleMedium: base.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
      labelLarge: base.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600, letterSpacing: 0.2),
      bodyLarge: base.textTheme.bodyLarge?.copyWith(height: 1.45),
      bodyMedium: base.textTheme.bodyMedium?.copyWith(height: 1.45),
    );
    final bordeRedondeado = RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md));

    return base.copyWith(
      scaffoldBackgroundColor: fondo,
      textTheme: texto,
      appBarTheme: AppBarTheme(
        backgroundColor: fondo,
        foregroundColor: esquema.onSurface,
        elevation: 0,
        scrolledUnderElevation: 1,
        surfaceTintColor: Colors.transparent,
        centerTitle: false,
        titleTextStyle: texto.titleLarge?.copyWith(color: esquema.onSurface),
      ),
      cardTheme: CardThemeData(
        color: esquema.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          side: BorderSide(color: esquema.outlineVariant.withValues(alpha: 0.6)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: esquema.surfaceContainerHighest.withValues(alpha: 0.5),
        contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.md),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.md), borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: BorderSide(color: esquema.outlineVariant.withValues(alpha: 0.5)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: BorderSide(color: esquema.primary, width: 1.6),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: BorderSide(color: esquema.error),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(AppSizes.botonAlto),
          shape: bordeRedondeado,
          textStyle: texto.labelLarge,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(AppSizes.botonAlto),
          shape: bordeRedondeado,
          textStyle: texto.labelLarge,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(minimumSize: const Size(AppSizes.toqueMinimo, AppSizes.toqueMinimo)),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: esquema.secondary,
        foregroundColor: esquema.onSecondary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.lg)),
      ),
      chipTheme: base.chipTheme.copyWith(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.sm)),
        side: BorderSide(color: esquema.outlineVariant),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        showDragHandle: true,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl))),
      ),
      dividerTheme: DividerThemeData(color: esquema.outlineVariant.withValues(alpha: 0.5), space: 1),
    );
  }
}
