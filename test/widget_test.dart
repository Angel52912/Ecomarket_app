import 'package:flutter_application_1/domain/entities/item_carrito.dart';
import 'package:flutter_application_1/domain/entities/producto.dart';
import 'package:flutter_application_1/domain/usecases/confirmar_compra.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Producto (entidad blindada)', () {
    test('stock negativo lanza AssertionError en debug', () {
      expect(
        () => Producto(
          id: 'x',
          nombre: 'Producto inválido',
          categoria: 'Hogar',
          precio: 10,
          stock: -1,
        ),
        throwsA(isA<AssertionError>()),
      );
    });

    test('precio negativo lanza AssertionError en debug', () {
      expect(
        () => Producto(
          id: 'x',
          nombre: 'Producto inválido',
          categoria: 'Hogar',
          precio: -5,
          stock: 1,
        ),
        throwsA(isA<AssertionError>()),
      );
    });

    test('nombre vacío lanza AssertionError en debug', () {
      expect(
        () => Producto(
          id: 'x',
          nombre: '',
          categoria: 'Hogar',
          precio: 10,
          stock: 1,
        ),
        throwsA(isA<AssertionError>()),
      );
    });

    test('getters computados: agotado y hayStockPara', () {
      const agotado = Producto(
        id: 'a',
        nombre: 'Agotado',
        categoria: 'Hogar',
        precio: 10,
        stock: 0,
      );
      const conStock = Producto(
        id: 'b',
        nombre: 'Con stock',
        categoria: 'Hogar',
        precio: 10,
        stock: 3,
      );

      expect(agotado.agotado, isTrue);
      expect(conStock.agotado, isFalse);
      expect(conStock.hayStockPara(3), isTrue);
      expect(conStock.hayStockPara(4), isFalse);
      expect(conStock.hayStockPara(0), isFalse);
      expect(conStock.hayStockPara(-1), isFalse);
    });

    test('copyWith crea una copia sin tocar el original (inmutabilidad)', () {
      const original = Producto(
        id: 'a',
        nombre: 'Original',
        categoria: 'Hogar',
        precio: 10,
        stock: 5,
      );
      final copia = original.copyWith(stock: 1);

      expect(original.stock, 5); // el original no cambió
      expect(copia.stock, 1);
      expect(copia.id, original.id);
      expect(copia.precio, original.precio);
    });
  });

  group('ItemCarrito', () {
    const producto = Producto(
      id: 'a',
      nombre: 'Jabón',
      categoria: 'Higiene',
      precio: 25.5,
      stock: 10,
    );

    test('cantidad no positiva lanza AssertionError', () {
      expect(
        () => ItemCarrito(producto: producto, cantidad: 0),
        throwsA(isA<AssertionError>()),
      );
    });

    test('subtotal es un getter computado', () {
      const item = ItemCarrito(producto: producto, cantidad: 3);
      expect(item.subtotal, closeTo(76.5, 0.001));
    });
  });

  group('ConfirmarCompra (atomicidad)', () {
    const confirmar = ConfirmarCompra();

    test('descuenta stock cuando hay disponibilidad', () {
      const catalogo = [
        Producto(id: 'a', nombre: 'Jabón', categoria: 'Higiene', precio: 25, stock: 10),
        Producto(id: 'b', nombre: 'Café', categoria: 'Alimentos', precio: 620, stock: 2),
      ];
      const carrito = [
        ItemCarrito(
          producto: Producto(
            id: 'a',
            nombre: 'Jabón',
            categoria: 'Higiene',
            precio: 25,
            stock: 10,
          ),
          cantidad: 3,
        ),
      ];

      final r = confirmar(catalogo, carrito);

      expect(r.exito, isTrue);
      expect(r.error, isNull);
      expect(r.catalogoActualizado.first.stock, 7);
      // el catálogo de entrada no se muta (las entidades son inmutables)
      expect(catalogo.first.stock, 10);
    });

    test('falla sin modificar NADA si el stock es insuficiente', () {
      const catalogo = [
        Producto(id: 'a', nombre: 'Jabón', categoria: 'Higiene', precio: 25, stock: 2),
        Producto(id: 'b', nombre: 'Café', categoria: 'Alimentos', precio: 620, stock: 5),
      ];
      const carrito = [
        // válido: 1 de 'a' (stock 2)
        ItemCarrito(
          producto: Producto(
            id: 'a',
            nombre: 'Jabón',
            categoria: 'Higiene',
            precio: 25,
            stock: 2,
          ),
          cantidad: 1,
        ),
        // inválido: 9 de 'b' cuando solo hay 5
        ItemCarrito(
          producto: Producto(
            id: 'b',
            nombre: 'Café',
            categoria: 'Alimentos',
            precio: 620,
            stock: 5,
          ),
          cantidad: 9,
        ),
      ];

      final r = confirmar(catalogo, carrito);

      expect(r.exito, isFalse);
      expect(r.error, contains('Stock insuficiente'));
      // Nada se tocó: ni el resultado ni el catálogo original
      expect(r.catalogoActualizado, same(catalogo));
      expect(catalogo.first.stock, 2);
      expect(catalogo.last.stock, 5);
    });
  });
}
