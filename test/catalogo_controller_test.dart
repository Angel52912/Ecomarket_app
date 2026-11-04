import 'package:flutter_application_1/domain/entities/producto.dart';
import 'package:flutter_application_1/domain/repositories/catalogo_repository.dart';
import 'package:flutter_application_1/domain/usecases/confirmar_compra.dart';
import 'package:flutter_application_1/domain/usecases/obtener_catalogo.dart';
import 'package:flutter_application_1/presentation/controllers/catalogo_controller.dart';
import 'package:flutter_test/flutter_test.dart';

/// Repo falso: devuelve un catálogo fijo sin delay, para aislar el test
/// de la fuente de datos (arquitectura hexagonal en acción).
class _RepoFalso implements CatalogoRepository {
  _RepoFalso(this._catalogo);
  final List<Producto> _catalogo;

  @override
  Future<List<Producto>> obtenerCatalogo() async => _catalogo;
}

void main() {
  const catalogoBase = [
    Producto(id: 'a', nombre: 'Jabón', categoria: 'Higiene', precio: 25, stock: 10),
    Producto(id: 'b', nombre: 'Café', categoria: 'Alimentos', precio: 620, stock: 2),
    Producto(id: 'c', nombre: 'Cepillo', categoria: 'Higiene', precio: 120, stock: 0),
  ];

  CatalogoController crearController() => CatalogoController(
        ObtenerCatalogo(_RepoFalso(catalogoBase)),
        const ConfirmarCompra(),
      );

  test('cargarCatalogo llena el catálogo y expone listas inmodificables',
      () async {
    final c = crearController();
    await c.cargarCatalogo();

    expect(c.productos, hasLength(3));
    expect(c.categorias, ['Alimentos', 'Higiene']);
    expect(() => c.productos.add(catalogoBase.first), throwsUnsupportedError);
  });

  test('productosVisibles filtra por categoría activa', () async {
    final c = crearController();
    await c.cargarCatalogo();

    expect(c.productosVisibles, hasLength(3));

    c.categoriaActiva = 'Higiene';
    expect(c.productosVisibles, hasLength(2));
    expect(c.productosVisibles.every((p) => p.categoria == 'Higiene'), isTrue);

    c.categoriaActiva = null;
    expect(c.productosVisibles, hasLength(3));
  });

  test('agregarAlCarrito respeta el stock disponible', () async {
    final c = crearController();
    await c.cargarCatalogo();

    expect(c.agregarAlCarrito(c.productos.first), isNull); // 1
    expect(c.agregarAlCarrito(c.productos.first), isNull); // 2
    expect(c.totalItems, 2);
    expect(c.total, closeTo(50.0, 0.001));

    // 'c' tiene stock 0 → debe rechazar
    final error = c.agregarAlCarrito(c.productos.last);
    expect(error, isNotNull);
    expect(error, contains('Sin stock suficiente'));
    expect(c.totalItems, 2); // no cambió
  });

  test('confirmarPago con stock insuficiente NO modifica nada (atomicidad)',
      () async {
    final c = crearController();
    await c.cargarCatalogo();

    // Defensa en profundidad: aunque la UI pase un snapshot desactualizado
    // del producto (stock 10), el caso de uso valida contra el catálogo
    // real (stock 2) y debe rechazar la compra entera.
    const snapshotDesactualizado = Producto(
      id: 'b',
      nombre: 'Café',
      categoria: 'Alimentos',
      precio: 620,
      stock: 10,
    );
    c.agregarAlCarrito(snapshotDesactualizado);
    c.agregarAlCarrito(snapshotDesactualizado);
    c.agregarAlCarrito(snapshotDesactualizado);
    expect(c.totalItems, 3);

    final error = c.confirmarPago();

    expect(error, isNotNull);
    expect(error, contains('Stock insuficiente'));
    // catálogo intacto, carrito intacto
    expect(c.productos[1].stock, 2);
    expect(c.carrito, hasLength(1));
    expect(c.totalItems, 3);
  });

  test('confirmarPago exitoso descuenta stock, vacía el carrito y notifica UNA vez',
      () async {
    final c = crearController();
    await c.cargarCatalogo();

    c.agregarAlCarrito(c.productos.first); // 1 Jabón
    c.agregarAlCarrito(c.productos.first); // 2 Jabones

    var notificaciones = 0;
    c.addListener(() => notificaciones++);

    final error = c.confirmarPago();

    expect(error, isNull);
    expect(notificaciones, 1); // UN solo notifyListeners()
    expect(c.carrito, isEmpty);
    expect(c.total, 0);
    expect(c.totalItems, 0);
    expect(c.productos.first.stock, 8); // 10 - 2
  });

  test('reabastecer suma stock, notifica UNA vez y valida en runtime', () async {
    final c = crearController();
    await c.cargarCatalogo();

    var notificaciones = 0;
    c.addListener(() => notificaciones++);

    c.reabastecer(unidades: 5);

    expect(notificaciones, 1);
    expect(c.productos.first.stock, 15);
    expect(c.productos[2].stock, 5); // el agotado también reabastece

    // unidades no positivas: se ignora sin notificar (validación en runtime)
    c.reabastecer(unidades: -3);
    expect(notificaciones, 1);
    expect(c.productos.first.stock, 15);
  });
}
