// NOTA (Rol 1 → coordinado con Rol 4): la semilla de datos ahora vive en
// `CatalogoRemoteDataSource._semilla` (B2.1 del ROL 4), que es quien simula
// la red. Aquí queda solo el modelo, que es lo que `domain` necesita ver.
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
}
