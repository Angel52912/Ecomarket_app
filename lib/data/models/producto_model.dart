import '../../domain/entities/producto.dart';

/// Modelo de datos: extiende la entidad del dominio y agrega el formato
/// de la fuente (JSON/Map). Es el único puente entre "cómo se ve el dato
/// afuera" y la entidad que usa el dominio.
class ProductoModel extends Producto {
  const ProductoModel({
    required super.id,
    required super.nombre,
    required super.categoria,
    required super.precio,
    required super.stock,
    super.imagenUrl,
  });

  factory ProductoModel.fromMap(Map<String, dynamic> map) => ProductoModel(
        id: map['id'] as String,
        nombre: map['nombre'] as String,
        categoria: map['categoria'] as String,
        precio: (map['precio'] as num).toDouble(),
        stock: map['stock'] as int,
        imagenUrl: map['imagenUrl'] as String?,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'nombre': nombre,
        'categoria': categoria,
        'precio': precio,
        'stock': stock,
        'imagenUrl': imagenUrl,
      };

  /// Datos semilla: 9 productos, 4 categorías, un `stock: 1` y un `stock: 0`
  /// para la prueba de estrés, y dos `imagenUrl: null` para demostrar
  /// el `errorBuilder` de la UI.
  static const List<ProductoModel> semilla = <ProductoModel>[
    // ---- Hogar ----
    ProductoModel(
      id: 'p01',
      nombre: 'Cesta de fibra de bambú',
      categoria: 'Hogar',
      precio: 450.00,
      stock: 12,
      imagenUrl: 'https://picsum.photos/seed/cesta/400/300',
    ),
    ProductoModel(
      id: 'p02',
      nombre: 'Limpiador multiusos ecológico',
      categoria: 'Hogar',
      precio: 180.50,
      stock: 30,
      imagenUrl: null, // sin imagen → la UI usa errorBuilder
    ),
    // ---- Higiene ----
    ProductoModel(
      id: 'p03',
      nombre: 'Jabón artesanal de lavanda',
      categoria: 'Higiene',
      precio: 95.00,
      stock: 40,
      imagenUrl: 'https://picsum.photos/seed/jabon/400/300',
    ),
    ProductoModel(
      id: 'p04',
      nombre: 'Cepillo de dientes de bambú',
      categoria: 'Higiene',
      precio: 120.00,
      stock: 1, // stock mínimo → prueba de estrés
      imagenUrl: 'https://picsum.photos/seed/cepillo/400/300',
    ),
    // ---- Alimentos ----
    ProductoModel(
      id: 'p05',
      nombre: 'Café orgánico 500 g',
      categoria: 'Alimentos',
      precio: 620.00,
      stock: 0, // agotado → prueba de estrés
      imagenUrl: 'https://picsum.photos/seed/cafe/400/300',
    ),
    ProductoModel(
      id: 'p06',
      nombre: 'Granola artesanal 400 g',
      categoria: 'Alimentos',
      precio: 310.00,
      stock: 18,
      imagenUrl: 'https://picsum.photos/seed/granola/400/300',
    ),
    // ---- Accesorios ----
    ProductoModel(
      id: 'p07',
      nombre: 'Botella de acero reutilizable 750 ml',
      categoria: 'Accesorios',
      precio: 890.00,
      stock: 7,
      imagenUrl: 'https://picsum.photos/seed/botella/400/300',
    ),
    ProductoModel(
      id: 'p08',
      nombre: 'Bolsa de algodón orgánico',
      categoria: 'Accesorios',
      precio: 250.00,
      stock: 25,
      imagenUrl: null, // sin imagen → la UI usa errorBuilder
    ),
    ProductoModel(
      id: 'p09',
      nombre: 'Popote de acero inoxidable',
      categoria: 'Accesorios',
      precio: 150.00,
      stock: 9,
      imagenUrl: 'https://picsum.photos/seed/popote/400/300',
    ),
  ];
}
