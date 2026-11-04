import '../../domain/entities/estado_entrega.dart';

/// GPS del repartidor: **Dart puro, sin `material.dart`**.
///
/// Un único `Stream` es la fuente de verdad: minutos, coordenadas y mensaje
/// salen del **mismo** `EstadoEntrega` en cada evento (nunca dos timers
/// separados, que es lo que descuadra la sincronización en la defensa).
class EntregaGpsDataSource {
  // Ruta simulada (lat, lng) de punta a punta (Merida, Yucatan).
  static const _ruta = <(double, double)>[
    (20.9754, -89.6170),
    (20.9731, -89.6139),
    (20.9702, -89.6101),
    (20.9680, -89.6062),
    (20.9655, -89.6030),
    (20.9630, -89.5998),
  ];

  /// Emite un estado cada 3 s; los minutos bajan 1 por ciclo hasta 0.
  ///
  /// `async*` convierte el método en un generador: cada `yield` publica un
  /// evento y el `await Future.delayed` pausa **sin** bloquear el hilo de UI.
  /// Al terminar el `while`, el stream se cierra solo (`ConnectionState.done`).
  Stream<EstadoEntrega> rastrear({int minutosIniciales = 5}) async* {
    var minutos = minutosIniciales;
    var paso = 0;

    while (minutos >= 0) {
      await Future.delayed(const Duration(seconds: 3)); // pausa realista

      // `int.clamp` devuelve `num`, así que indexamos con una guarda explícita
      // para quedarnos en el último punto de la ruta cuando se acaba.
      final idx = paso >= _ruta.length ? _ruta.length - 1 : paso;
      final (lat, lng) = _ruta[idx];

      yield EstadoEntrega(
        minutosRestantes: minutos,
        latitud: lat,
        longitud: lng,
        mensaje: minutos == 0
            ? '¡Tu pedido llegó!'
            : 'Tu repartidor va en camino',
      );

      minutos--;
      paso++;
    }
  }
}
