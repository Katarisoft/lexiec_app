import 'package:flutter_test/flutter_test.dart';
import 'package:lexiec/controllers/validadores.dart';

void main() {
  test('usuario: longitud y caracteres permitidos (mismas reglas que la API)', () {
    expect(Validadores.usuario('ab'), isNotNull);
    expect(Validadores.usuario('con espacio'), isNotNull);
    expect(Validadores.usuario('maria.perez_01-x'), isNull);
    expect(Validadores.usuario('a' * 51), isNotNull);
  });

  test('clave nueva: mínimo 12 y sin contener el usuario', () {
    expect(Validadores.claveNueva('corta'), isNotNull);
    expect(
      Validadores.claveNueva('clave-de-maria.perez', usuario: 'Maria.Perez'),
      'No debe contener tu nombre de usuario.',
    );
    expect(Validadores.claveNueva('una frase larga y segura', usuario: 'maria'), isNull);
  });

  test('confirmación, correo y nombre opcionales', () {
    expect(Validadores.confirmacion('a', 'b'), isNotNull);
    expect(Validadores.correoOpcional(''), isNull);
    expect(Validadores.correoOpcional('no-es-correo'), isNotNull);
    expect(Validadores.correoOpcional('maria@ejemplo.edu.ec'), isNull);
    expect(Validadores.nombreOpcional('x' * 121), isNotNull);
    expect(Validadores.opcional('   '), isNull);
  });
}
