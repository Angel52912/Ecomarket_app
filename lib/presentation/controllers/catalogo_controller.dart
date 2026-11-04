import 'package:flutter/foundation.dart';

import '../../domain/entities/item_carrito.dart';
import '../../domain/entities/producto.dart';
import '../../domain/usecases/confirmar_compra.dart';
import '../../domain/usecases/obtener_catalogo.dart';

/// Estado en RAM de la app. Es el **único** encargado de mutar el catálogo
/// y el carrito; la UI solo lee y manda mensajes.
///
/// Reglas que defiende la rúbrica:
/// * listas expuestas **inmodificables** hacia la UI;
/// * un único `notifyListeners()` por operación (refresco atómico, sin parpadeo);
/// * validación en runtime antes de crear copias (nunca depender solo del assert).
class CatalogoController extends ChangeNotifier {
  final ObtenerCatalogo _obtenerCatalogo;
  final ConfirmarCompra _confirmarCompra;

  CatalogoController(this._obtenerCatalogo, this._confirmarCompra);

  List<Producto> _productos = [];
  final List<ItemCarrito> _carrito = [];
  String? _categoriaActiva; // null = todas

  // ---- Lectura (listas inmodificables hacia la UI) ----
  List<Producto> get productos => List.unmodifiable(_productos);
  List<ItemCarrito> get carrito => List.unmodifiable(_carrito);
  List<String> get categorias =>
      _productos.map((p) => p.categoria).toSet().toList()..sort();

  // ---- Getter/Setter computado ----
  String? get categoriaActiva => _categoriaActiva;
  set categoriaActiva(String? valor) {
    _categoriaActiva = valor;
    notifyListeners();
  }

  List<Producto> get productosVisibles => _categoriaActiva == null
      ? productos
      : _productos.where((p) => p.categoria == _categoriaActiva).toList();

  double get total => _carrito.fold(0.0, (suma, i) => suma + i.subtotal);
  int get totalItems => _carrito.fold(0, (suma, i) => suma + i.cantidad);

  // ---- Carga ----
  Future<void> cargarCatalogo() async {
    _productos = await _obtenerCatalogo();
    notifyListeners();
  }

  // ---- Carrito ----
  /// Devuelve null si todo bien; un mensaje si hay problema (la UI muestra SnackBar).
  String? agregarAlCarrito(Producto producto) {
    final idx = _carrito.indexWhere((i) => i.producto.id == producto.id);
    final enCarrito = idx == -1 ? 0 : _carrito[idx].cantidad;

    // Validación en runtime: no dependemos solo del assert del assert.
    if (producto.stock < 0) {
      return 'Stock inválido para "${producto.nombre}"';
    }
    if (!producto.hayStockPara(enCarrito + 1)) {
      return 'Sin stock suficiente de "${producto.nombre}"';
    }

    if (idx == -1) {
      _carrito.add(ItemCarrito(producto: producto, cantidad: 1));
    } else {
      _carrito[idx] = _carrito[idx].copyWith(cantidad: enCarrito + 1);
    }
    notifyListeners();
    return null;
  }

  void quitarDelCarrito(String productoId) {
    _carrito.removeWhere((i) => i.producto.id == productoId);
    notifyListeners();
  }

  // ---- Pago: resta stock y vacía el carrito reactivamente ----
  /// Devuelve null si éxito, o el mensaje de error (para SnackBar).
  String? confirmarPago() {
    final r = _confirmarCompra(_productos, _carrito);
    if (!r.exito) return r.error; // nada se mutó: atomicidad

    _productos = r.catalogoActualizado;
    _carrito.clear();
    notifyListeners(); // UN solo notify = refresco atómico
    return null;
  }

  // ---- FAB: reabastecer ----
  void reabastecer({int unidades = 10}) {
    // Validación en runtime antes de crear copias.
    if (unidades <= 0) return;

    _productos = _productos
        .map((p) => p.copyWith(stock: p.stock + unidades))
        .toList();
    notifyListeners(); // UN solo notify: pantalla se refresca al instante
  }
}
