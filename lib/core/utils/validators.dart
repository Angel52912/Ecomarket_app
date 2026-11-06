/// Validadores del checkout (Rol 3).
///
/// Dart puro (sin imports de Flutter) para poder probarlos sin UI.
/// Convención de `FormField.validator`: devuelven `null` si el valor es
/// válido, o el mensaje de error que se pinta en rojo bajo el campo.
///
/// Nulabilidad: `v` puede ser `null` si el campo no se ha tocado; siempre se
/// usa `v?.trim() ?? ''`, nunca `v!`.
class Validators {
  Validators._();

  static final RegExp _soloLetras =
      RegExp(r'^[A-Za-zÁÉÍÓÚÜÑáéíóúüñ]+(?: [A-Za-zÁÉÍÓÚÜÑáéíóúüñ]+)*$');
  static final RegExp _correo =
      RegExp(r'^[\w.+-]+@[A-Za-z0-9-]+(\.[A-Za-z0-9-]+)*\.[A-Za-z]{2,}$');
  static final RegExp _telefono = RegExp(r'^\d{10}$');
  static final RegExp _codigoPostal = RegExp(r'^\d{5}$');

  static String? nombre(String? v) {
    final t = v?.trim() ?? '';
    if (t.isEmpty) return 'El nombre es obligatorio';
    if (t.length < 3) return 'Mínimo 3 caracteres';
    if (!_soloLetras.hasMatch(t)) return 'Solo letras y espacios';
    return null;
  }

  static String? correo(String? v) {
    final t = v?.trim() ?? '';
    if (t.isEmpty) return 'El correo es obligatorio';
    if (!_correo.hasMatch(t)) {
      return 'Correo no válido (ej. nombre@dominio.com)';
    }
    return null;
  }

  static String? telefono(String? v) {
    final t = v?.trim() ?? '';
    if (t.isEmpty) return 'El teléfono es obligatorio';
    if (!_telefono.hasMatch(t)) return 'Debe tener exactamente 10 dígitos';
    return null;
  }

  static String? direccion(String? v) {
    final t = v?.trim() ?? '';
    if (t.isEmpty) return 'La dirección es obligatoria';
    if (t.length < 8) return 'Escribe una dirección más completa';
    return null;
  }

  static String? codigoPostal(String? v) {
    final t = v?.trim() ?? '';
    if (t.isEmpty) return 'El código postal es obligatorio';
    if (!_codigoPostal.hasMatch(t)) return 'Debe tener 5 dígitos';
    return null;
  }
}
