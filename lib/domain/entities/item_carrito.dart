import 'producto.dart';

/// Línea del carrito: un producto + la cantidad elegida.
/// También es inmutable y su `subtotal` es un getter computado.
class ItemCarrito {
  final Producto producto;
  final int cantidad;

  const ItemCarrito({required this.producto, required this.cantidad})
      : assert(cantidad > 0, 'La cantidad debe ser positiva');

  /// Getter computado: no se guarda, se deriva.
  double get subtotal => producto.precio * cantidad;

  ItemCarrito copyWith({int? cantidad}) => ItemCarrito(
        producto: producto,
        cantidad: cantidad ?? this.cantidad,
      );
}
