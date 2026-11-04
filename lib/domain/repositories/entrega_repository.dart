import '../entities/estado_entrega.dart';

/// Contrato (puerto) del seguimiento de entrega en vivo.
abstract class EntregaRepository {
  /// El Rol 4 emite un estado cada 3 s.
  Stream<EstadoEntrega> seguirEntrega();
}
