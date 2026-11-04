/// Contrato de la entrega en vivo (lo consume el Rol 4).
/// La capa `domain` define el formato; la fuente GPS es un detalle de `data`.
class EstadoEntrega {
  final int minutosRestantes;
  final double latitud;
  final double longitud;
  final String mensaje;

  const EstadoEntrega({
    required this.minutosRestantes,
    required this.latitud,
    required this.longitud,
    required this.mensaje,
  });

  /// Getter computado: la UI no calcula, solo pregunta.
  bool get llego => minutosRestantes <= 0;
}
