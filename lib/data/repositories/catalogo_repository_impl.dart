import '../../domain/entities/producto.dart';
import '../../domain/repositories/catalogo_repository.dart';
import '../datasources/catalogo_remote_datasource.dart';

/// Implementación concreta del repositorio de catálogo.
/// Traduce lo que devuelve el datasource (modelos) al lenguaje del dominio
/// (entidades). Es el único lugar donde `data` conoce el formato del dato.
class CatalogoRepositoryImpl implements CatalogoRepository {
  final CatalogoRemoteDataSource _dataSource;
  CatalogoRepositoryImpl(this._dataSource);

  @override
  Future<List<Producto>> obtenerCatalogo() async {
    final modelos = await _dataSource.obtenerCatalogo();
    // Ya son Producto (ProductoModel extiende Producto): se exponen como
    // lista inmutable para que nadie las altere desde afuera.
    return List<Producto>.unmodifiable(modelos);
  }
}
