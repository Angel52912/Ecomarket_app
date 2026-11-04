/// Entidad raíz del catálogo.
///
/// Reglas de la capa `domain`:
/// * Dart puro: **no** importa `flutter` ni nada de `data`/`presentation`.
/// * Inmutable: para cambiar un valor se crea una copia con [copyWith].
/// * Blindada con `assert` (solo corren en debug) + validación en runtime
///   en el controller, nunca dependemos solo del `assert`.
class Producto {
  final String id;
  final String nombre;
  final String categoria;
  final double precio;
  final int stock;
  final String? imagenUrl; // nulabilidad explícita: puede no haber imagen

  // Lista de inicialización + assert: valores negativos imposibles en desarrollo
  const Producto({
    required this.id,
    required this.nombre,
    required this.categoria,
    required this.precio,
    required this.stock,
    this.imagenUrl,
  })  : assert(precio >= 0, 'El precio no puede ser negativo'),
        assert(stock >= 0, 'El stock no puede ser negativo'),
        assert(nombre != '', 'El nombre no puede estar vacío');

  // Getters computados
  bool get agotado => stock == 0;
  bool hayStockPara(int cantidad) => cantidad > 0 && cantidad <= stock;

  // Inmutabilidad: para "mutar" se crea una copia
  Producto copyWith({int? stock, double? precio}) => Producto(
        id: id,
        nombre: nombre,
        categoria: categoria,
        precio: precio ?? this.precio,
        stock: stock ?? this.stock,
        imagenUrl: imagenUrl,
      );
}
