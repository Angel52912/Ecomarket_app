// NOTA (Rol 1): stub mínimo para desbloquear `flutter analyze` y la demo.
// El Rol 4 debe reemplazar esta clase por su GPS real emitiendo cada 3 s.
import '../../domain/entities/estado_entrega.dart';

class EntregaGpsDataSource {
  /// Emite un estado de entrega cada 3 s (Rol 4).
  Stream<EstadoEntrega> seguirEntrega() async* {
    var minutos = 12;
    var lat = -34.6037;
    var lng = -58.3816;

    while (minutos > -3) {
      yield EstadoEntrega(
        minutosRestantes: minutos,
        latitud: lat,
        longitud: lng,
        mensaje: minutos <= 0
            ? '¡Pedido entregado!'
            : 'Tu pedido llega en $minutos min',
      );
      await Future<void>.delayed(const Duration(seconds: 3));
      minutos -= 3;
      lat += 0.004;
      lng += 0.004;
    }
  }
}
