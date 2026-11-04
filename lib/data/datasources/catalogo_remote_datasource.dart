import '../models/producto_model.dart';

/// Fuente remota del catálogo: **Dart puro, sin `material.dart`**.
///
/// Simula la latencia de una API real con un `Future.delayed` de 1 s.
/// El retardo vive aquí (capa `data`), nunca en los widgets.
class CatalogoRemoteDataSource {
  /// Simula una llamada de red.
  Future<List<ProductoModel>> fetchProductos() async {
    await Future.delayed(const Duration(seconds: 1)); // retardo de red simulado
    return _semilla;
  }

  // Mínimo 8 productos: uno con stock 1, uno con stock 0, uno sin imagen
  // y uno con URL inválida para forzar el `errorBuilder` de la UI.
  static const List<ProductoModel> _semilla = [
    ProductoModel(
      id: 'p1',
      nombre: 'Botella reutilizable de acero',
      categoria: 'Hogar',
      precio: 249.0,
      stock: 12,
      imagenUrl: 'https://picsum.photos/seed/botella/400/500',
    ),
    ProductoModel(
      id: 'p2',
      nombre: 'Cepillo de bambú (pack 4)',
      categoria: 'Higiene',
      precio: 99.0,
      stock: 20,
      imagenUrl: 'https://picsum.photos/seed/cepillo/400/500',
    ),
    ProductoModel(
      id: 'p3',
      nombre: 'Bolsas de tela orgánica',
      categoria: 'Accesorios',
      precio: 129.0,
      stock: 1, // stock mínimo → prueba de estrés
      imagenUrl: 'https://picsum.photos/seed/bolsas/400/500',
    ),
    ProductoModel(
      id: 'p4',
      nombre: 'Jabón artesanal de avena',
      categoria: 'Higiene',
      precio: 59.0,
      stock: 0, // agotado → prueba de estrés
      imagenUrl: 'https://picsum.photos/seed/jabon/400/500',
    ),
    ProductoModel(
      id: 'p5',
      nombre: 'Granola orgánica 500 g',
      categoria: 'Alimentos',
      precio: 89.0,
      stock: 15,
      imagenUrl: null, // sin imagen → errorBuilder
    ),
    ProductoModel(
      id: 'p6',
      nombre: 'Popotes de vidrio (set)',
      categoria: 'Hogar',
      precio: 79.0,
      stock: 8,
      imagenUrl: 'https://url-invalida.example/img.png', // fuerza errorBuilder
    ),
    ProductoModel(
      id: 'p7',
      nombre: 'Café de altura molido',
      categoria: 'Alimentos',
      precio: 159.0,
      stock: 6,
      imagenUrl: 'https://picsum.photos/seed/cafe/400/500',
    ),
    ProductoModel(
      id: 'p8',
      nombre: 'Lonchera de acero inoxidable',
      categoria: 'Accesorios',
      precio: 319.0,
      stock: 4,
      imagenUrl: 'https://picsum.photos/seed/lonchera/400/500',
    ),
  ];
}
