import 'package:flutter_test/flutter_test.dart';
import 'package:lexiec/core/config/app_config.dart';

void main() {
  test('sin API_BASE_URL usa el servidor de producción por HTTPS', () {
    expect(AppConfig.apiBaseUrl, 'https://lexiec.katarisoft.com/api/v1');
  });

  test('normalizarUrl quita espacios y barras finales', () {
    expect(AppConfig.normalizarUrl(' http://10.0.2.2:8010/api/v1// '), 'http://10.0.2.2:8010/api/v1');
  });
}
