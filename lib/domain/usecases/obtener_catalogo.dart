import '../entities/producto.dart';
import '../repositories/catalogo_repository.dart';

/// Caso de uso: leer el catálogo completo.
/// Toda la orquestación vive fuera de los widgets.
class ObtenerCatalogo {
  final CatalogoRepository _repo;
  const ObtenerCatalogo(this._repo);

  Future<List<Producto>> call() => _repo.obtenerCatalogo();
}
