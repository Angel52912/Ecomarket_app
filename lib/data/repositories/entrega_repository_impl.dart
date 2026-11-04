// NOTA (Rol 1): stub mínimo para desbloquear `flutter analyze` y la demo.
// El Rol 4 debe reemplazarlo por su implementación real.
import '../../domain/entities/estado_entrega.dart';
import '../../domain/repositories/entrega_repository.dart';
import '../datasources/entrega_gps_datasource.dart';

class EntregaRepositoryImpl implements EntregaRepository {
  final EntregaGpsDataSource _dataSource;
  EntregaRepositoryImpl(this._dataSource);

  @override
  Stream<EstadoEntrega> seguirEntrega() => _dataSource.seguirEntrega();
}
