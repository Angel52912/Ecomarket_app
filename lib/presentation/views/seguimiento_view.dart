import 'package:flutter/material.dart';

import '../../domain/entities/estado_entrega.dart';
import '../../domain/usecases/seguir_entrega.dart';

/// Vista de seguimiento del repartidor: **`StreamBuilder` dedicado**.
///
/// Sincronización de un solo origen: minutos, coordenadas y mensaje llegan
/// en el mismo `EstadoEntrega`, así el reloj nunca se descuadra.
class SeguimientoView extends StatefulWidget {
  final SeguirEntrega seguirEntrega;

  const SeguimientoView({super.key, required this.seguirEntrega});

  @override
  State<SeguimientoView> createState() => _SeguimientoViewState();
}

class _SeguimientoViewState extends State<SeguimientoView> {
  // Se crea UNA sola vez: reconstruir la vista (rotación, setState externo)
  // no reinicia el reloj ni re-suscribe el stream.
  late final Stream<EstadoEntrega> _stream = widget.seguirEntrega();

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Seguimiento de entrega')),
      body: Center(
        child: ConstrainedBox(
          // maxWidth: 520 → en tabletas/escritorio el contenido no se estira
          // hasta el borde; en 320 px se adapta al ancho disponible.
          constraints: const BoxConstraints(maxWidth: 520),
          child: StreamBuilder<EstadoEntrega>(
            stream: _stream,
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return const Text('Se perdió la señal del GPS');
              }

              final estado = snapshot.data; // nulo hasta el primer evento
              if (estado == null) {
                return const Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Conectando con el repartidor…'),
                  ],
                );
              }

              return Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      estado.llego
                          ? Icons.check_circle
                          : Icons.delivery_dining,
                      size: 72,
                      color: t.colorScheme.primary,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      estado.mensaje,
                      style: t.textTheme.titleLarge,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      estado.llego
                          ? 'Entregado'
                          : '${estado.minutosRestantes} min restantes',
                      style: t.textTheme.displaySmall,
                    ),
                    const SizedBox(height: 16),
                    // Wrap evita overflow de las coordenadas en pantallas angostas
                    Wrap(
                      spacing: 12,
                      runSpacing: 8,
                      alignment: WrapAlignment.center,
                      children: [
                        Chip(
                          label: Text(
                            'Lat ${estado.latitud.toStringAsFixed(4)}',
                          ),
                        ),
                        Chip(
                          label: Text(
                            'Lng ${estado.longitud.toStringAsFixed(4)}',
                          ),
                        ),
                      ],
                    ),
                    if (snapshot.connectionState == ConnectionState.done) ...[
                      const SizedBox(height: 24),
                      FilledButton(
                        onPressed: () =>
                            Navigator.of(context).popUntil((r) => r.isFirst),
                        child: const Text('Volver al catálogo'),
                      ),
                    ],
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
