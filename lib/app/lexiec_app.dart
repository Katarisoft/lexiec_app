import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:get/get.dart';

import 'bindings/inicial_binding.dart';
import 'routes/app_pages.dart';
import 'routes/app_routes.dart';
import 'theme/app_theme.dart';

class LexiecApp extends StatelessWidget {
  const LexiecApp({super.key, this.bindingInicial, this.rutaInicial = AppRoutes.inicio});

  /// Dependencias globales; las pruebas inyectan versiones falsas.
  final Bindings? bindingInicial;
  final String rutaInicial;

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'LexiEC',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.claro(),
      darkTheme: AppTheme.oscuro(),
      themeMode: ThemeMode.system,
      locale: const Locale('es'),
      fallbackLocale: const Locale('es'),
      supportedLocales: const [Locale('es')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      initialBinding: bindingInicial ?? InicialBinding(),
      initialRoute: rutaInicial,
      getPages: AppPages.paginas,
      defaultTransition: Transition.fadeIn,
    );
  }
}
