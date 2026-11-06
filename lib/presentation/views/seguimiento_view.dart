import 'package:flutter/material.dart';

import '../../domain/entities/estado_entrega.dart';
import '../../domain/usecases/seguir_entrega.dart';

/// Vista de seguimiento del repartidor: **`StreamBuilder` dedicado**.
///
/// Sincronización de un solo origen: minutos, coordenadas y mensaje llegan
/// en el mismo `EstadoEntrega`, así el reloj nunca se descuadra.
///
/// **Responsiva (320 px → escritorio):** `LayoutBuilder` ajusta padding,
/// tamaño del icono y tipografía al ancho disponible; `SingleChildScrollView`
/// con `minHeight` da centrado vertical **y** scroll en horizontal, así nunca
/// hay overflow de altura en landscape (QA del ROL 4).
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
      body: LayoutBuilder(
        builder: (context, constraints) {
          // Ancho disponible → decide la "densidad" de la pantalla.
          final compacto = constraints.maxWidth < 380;
          final padding = EdgeInsets.all(compacto ? 16 : 24);
          final icono = compacto ? 56.0 : 72.0;

          // Scroll + minHeight: en landscape (p. ej. 891x411) el contenido
          // cabe con scroll en vez de desbordar; en vertical se centra.
          return SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: Center(
                child: ConstrainedBox(
                  // maxWidth: 520 → en tabletas/escritorio el contenido no
                  // se estira hasta el borde; en 320 px se adapta al ancho.
                  constraints: const BoxConstraints(maxWidth: 520),
                  child: StreamBuilder<EstadoEntrega>(
                    stream: _stream,
                    builder: (context, snapshot) {
                      if (snapshot.hasError) {
                        return Padding(
                          padding: padding,
                          child: const Text(
                            'Se perdió la señal del GPS',
                            textAlign: TextAlign.center,
                          ),
                        );
                      }

                      final estado = snapshot.data; // nulo hasta el 1er evento
                      if (estado == null) {
                        return Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const CircularProgressIndicator(),
                            SizedBox(height: compacto ? 12 : 16),
                            const Text(
                              'Conectando con el repartidor…',
                              textAlign: TextAlign.center,
                            ),
                          ],
                        );
                      }

                      return Padding(
                        padding: padding,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              estado.llego
                                  ? Icons.check_circle
                                  : Icons.delivery_dining,
                              size: icono,
                              color: t.colorScheme.primary,
                            ),
                            SizedBox(height: compacto ? 12 : 16),
                            Text(
                              estado.mensaje,
                              style: compacto
                                  ? t.textTheme.titleMedium
                                  : t.textTheme.titleLarge,
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 8),
                            // FittedBox: el texto de minutos nunca desborda
                            // aunque crezca con escala de fuente del sistema.
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                estado.llego
                                    ? 'Entregado'
                                    : '${estado.minutosRestantes} min restantes',
                                style: t.textTheme.displaySmall,
                                textAlign: TextAlign.center,
                              ),
                            ),
                            const SizedBox(height: 16),
                            // Wrap evita overflow de coordenadas en 320 px
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
                            if (snapshot.connectionState ==
                                ConnectionState.done) ...[
                              const SizedBox(height: 24),
                              FilledButton(
                                onPressed: () => Navigator.of(context)
                                    .popUntil((r) => r.isFirst),
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
            ),
          );
        },
      ),
    );
  }
}
