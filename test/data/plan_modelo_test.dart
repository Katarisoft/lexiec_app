import 'package:flutter_test/flutter_test.dart';
import 'package:lexiec/data/models/plan.dart';

void main() {
  test('EstadoPlan.fromJson con lotes vigentes (guía de la API, § 6.11)', () {
    final plan = EstadoPlan.fromJson({
      'modo': 'pagado',
      'ia_rapida': true,
      'consultas_pagadas': 18,
      'gratis_limite': 5,
      'gratis_restantes': 5,
      'gratis_renueva_en': '2026-11-01T05:00:00Z',
      'lotes': [
        {
          'plan': 'paquete_20',
          'nombre': 'Paquete 20',
          'restantes': 18,
          'total': 20,
          'vence_en': '2027-04-19T15:02:11Z',
        },
      ],
    });
    expect(plan.modo, ModoPlan.pagado);
    expect(plan.iaRapida, isTrue);
    expect(plan.lotes.single.restantes, 18);
    expect(plan.gratisRenuevaEn, DateTime.utc(2026, 11, 1, 5));
  });

  test('modo desconocido no rompe la app', () {
    expect(ModoPlan.desde('sin_saldo'), ModoPlan.sinSaldo);
    expect(ModoPlan.desde('premium_futuro'), ModoPlan.desconocido);
  });

  test('PlanCatalogo: precio como texto y vigencia legible', () {
    final p = PlanCatalogo.fromJson({
      'codigo': 'paquete_20',
      'nombre': 'Paquete 20',
      'consultas': 20,
      'dias': 180,
      'precio_usd': '4.99',
      'descripcion': '20 consultas.',
    });
    expect(p.precioUsd, '4.99');
    expect(p.vigencia, '6 meses');
    expect(
      PlanCatalogo.fromJson({
        ...{'codigo': 'p', 'nombre': 'P', 'consultas': 300, 'precio_usd': '19.99', 'descripcion': ''},
        'dias': 30,
      }).vigencia,
      '30 días',
    );
  });
}
