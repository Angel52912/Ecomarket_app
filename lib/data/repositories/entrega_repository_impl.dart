import '../../domain/entities/estado_entrega.dart';
import '../../domain/repositories/entrega_repository.dart';
import '../datasources/entrega_gps_datasource.dart';

/// Implementación concreta del contrato `EntregaRepository` (Rol 1).
/// Traduce el lenguaje del datasource (`rastrear`) al del dominio
/// (`seguirEntrega`): `data` habla el idioma de `domain`, no al revés.
class EntregaRepositoryImpl implements EntregaRepository {
  final EntregaGpsDataSource _gps;
  const EntregaRepositoryImpl(this._gps);

  @override
  Stream<EstadoEntrega> seguirEntrega() => _gps.rastrear();
}
