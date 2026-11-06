import 'package:flutter_application_1/core/utils/validators.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Validators.nombre', () {
    test('acepta nombres con acentos y espacios', () {
      expect(Validators.nombre('José Abraham Cámara'), isNull);
      expect(Validators.nombre('  Ana  '), isNull); // se recorta
    });
    test('rechaza vacío, null, corto, números y dobles espacios', () {
      expect(Validators.nombre(null), 'El nombre es obligatorio');
      expect(Validators.nombre('   '), 'El nombre es obligatorio');
      expect(Validators.nombre('Al'), 'Mínimo 3 caracteres');
      expect(Validators.nombre('Ana 123'), 'Solo letras y espacios');
      expect(Validators.nombre('Ana  Luz'), 'Solo letras y espacios');
    });
  });

  group('Validators.correo', () {
    test('acepta correos válidos', () {
      expect(Validators.correo('a@b.com'), isNull);
      expect(Validators.correo('nombre.apellido+eco@uni.edu.mx'), isNull);
    });
    test('rechaza correos inválidos y null', () {
      expect(Validators.correo(null), isNotNull); // nulabilidad controlada
      expect(Validators.correo(''), 'El correo es obligatorio');
      expect(Validators.correo('a@b'), isNotNull);
      expect(Validators.correo('abc@'), isNotNull);
      expect(Validators.correo('@dominio.com'), isNotNull);
      expect(Validators.correo('a b@c.com'), isNotNull);
    });
  });

  group('Validators.telefono', () {
    test('exactamente 10 dígitos', () {
      expect(Validators.telefono('9991234567'), isNull);
      expect(Validators.telefono('999123'), isNotNull);
      expect(Validators.telefono('99912345678'), isNotNull);
      expect(Validators.telefono('99912345ab'), isNotNull);
      expect(Validators.telefono(null), 'El teléfono es obligatorio');
    });
  });

  group('Validators.direccion', () {
    test('mínimo 8 caracteres', () {
      expect(Validators.direccion('Calle 60 #123, Centro'), isNull);
      expect(Validators.direccion('Calle 1'), isNotNull);
      expect(Validators.direccion(null), 'La dirección es obligatoria');
    });
  });

  group('Validators.codigoPostal', () {
    test('exactamente 5 dígitos', () {
      expect(Validators.codigoPostal('97000'), isNull);
      expect(Validators.codigoPostal('9700'), isNotNull);
      expect(Validators.codigoPostal('97a00'), isNotNull);
      expect(Validators.codigoPostal(null), 'El código postal es obligatorio');
    });
  });
}
