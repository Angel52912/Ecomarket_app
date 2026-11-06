import '../entities/item_carrito.dart';
import '../entities/producto.dart';

/// Resultado de una compra: o sale bien, o falla **sin haber mutado nada**.
class ResultadoCompra {
  final bool exito;
  final String? error; // null si todo salió bien
  final List<Producto> catalogoActualizado;

  const ResultadoCompra.ok(this.catalogoActualizado)
    : exito = true,
      error = null;
  const ResultadoCompra.fallo(this.error, this.catalogoActualizado)
    : exito = false;
}

/// Caso de uso con la **regla de negocio pura**: recibe catálogo + carrito y
/// devuelve el catálogo con stock descontado, o un fallo si hay stock
/// insuficiente. Es Dart puro: no toca Flutter ni el estado global.
class ConfirmarCompra {
  const ConfirmarCompra();

  ResultadoCompra call(List<Producto> catalogo, List<ItemCarrito> carrito) {
    // 1) Validar antes de mutar nada (atomicidad)
    for (final item in carrito) {
      final real = catalogo.firstWhere((p) => p.id == item.producto.id);
      if (!real.hayStockPara(item.cantidad)) {
        return ResultadoCompra.fallo(
          'Stock insuficiente de "${real.nombre}" (disponible: ${real.stock})',
          catalogo,
        );
      }
    }

    // 2) Aplicar descuento
    final nuevo = catalogo.map((p) {
      final pedido = carrito.where((i) => i.producto.id == p.id);
      if (pedido.isEmpty) return p;
      return p.copyWith(stock: p.stock - pedido.first.cantidad);
    }).toList();

    return ResultadoCompra.ok(nuevo);
  }
}
