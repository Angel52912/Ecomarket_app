import '../entities/producto.dart';

/// Contrato (puerto) que la capa `data` debe implementar.
/// `domain` no sabe si viene de una API, SQLite o memoria: solo define el qué.
abstract class CatalogoRepository {
  /// El Rol 4 lo respalda con un delay de 1 s.
  Future<List<Producto>> obtenerCatalogo();
}
