import '../entities/estado_entrega.dart';
import '../repositories/entrega_repository.dart';

/// Caso de uso: suscribirse al seguimiento de la entrega en vivo.
class SeguirEntrega {
  final EntregaRepository _repo;
  const SeguirEntrega(this._repo);

  Stream<EstadoEntrega> call() => _repo.seguirEntrega();
}
