/// Validaciones locales con las mismas reglas que la API (guía § 5), para
/// avisar antes de enviar. Devuelven el mensaje de error o null si es válido.
abstract final class Validadores {
  static final RegExp _patronUsuario = RegExp(r'^[A-Za-z0-9._-]+$');
  static final RegExp _patronCorreo = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]{2,}$');

  static String? requerido(String? valor, String mensaje) => (valor ?? '').trim().isEmpty ? mensaje : null;

  static String? usuario(String? valor) {
    final v = (valor ?? '').trim();
    if (v.isEmpty) return 'Ingresa un nombre de usuario.';
    if (v.length < 3) return 'Debe tener al menos 3 caracteres.';
    if (v.length > 50) return 'Debe tener como máximo 50 caracteres.';
    if (!_patronUsuario.hasMatch(v)) return 'Usa solo letras, números, punto, guion o guion bajo.';
    return null;
  }

  static String? claveNueva(String? valor, {String usuario = ''}) {
    final v = valor ?? '';
    if (v.isEmpty) return 'Ingresa una clave.';
    if (v.length < 12) return 'Debe tener al menos 12 caracteres.';
    if (v.length > 128) return 'Debe tener como máximo 128 caracteres.';
    final u = usuario.trim().toLowerCase();
    if (u.isNotEmpty && v.toLowerCase().contains(u)) return 'No debe contener tu nombre de usuario.';
    return null;
  }

  static String? confirmacion(String? valor, String clave) => valor != clave ? 'Las claves no coinciden.' : null;

  static String? correoOpcional(String? valor) {
    final v = (valor ?? '').trim();
    return v.isNotEmpty && !_patronCorreo.hasMatch(v) ? 'El correo electrónico no es válido.' : null;
  }

  static String? nombreOpcional(String? valor) =>
      (valor ?? '').trim().length > 120 ? 'Debe tener como máximo 120 caracteres.' : null;

  /// Valor opcional: null si está vacío.
  static String? opcional(String valor) => valor.trim().isEmpty ? null : valor.trim();
}
