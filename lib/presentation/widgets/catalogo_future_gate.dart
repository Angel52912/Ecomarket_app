import 'package:flutter/material.dart';

/// Compuerta de carga del catálogo: **`FutureBuilder` dedicado**.
///
/// Aísla los tres estados de una petición (carga / error / datos) para que la
/// UI nunca se congele ni muestre una pantalla vacía.
///
/// ⚠️ El `Future` **no se crea aquí**: se recibe desde `initState`/`late final`
/// del padre. Si se creara dentro de `build()`, cada redibujado relanzaría la
/// petición en bucle (error clásico que baja la nota).
class CatalogoFutureGate extends StatelessWidget {
  final Future<void> future;
  final VoidCallback onRetry;
  final Widget child;

  const CatalogoFutureGate({
    super.key,
    required this.future,
    required this.onRetry,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: future, // viene de initState / late final: NO se crea aquí
      builder: (context, snapshot) {
        switch (snapshot.connectionState) {
          case ConnectionState.none:
          case ConnectionState.waiting:
            return const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Cargando catálogo ecológico…'),
                ],
              ),
            );
          case ConnectionState.active:
          case ConnectionState.done:
            if (snapshot.hasError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.cloud_off,
                        size: 48,
                        color: Theme.of(context).colorScheme.error,
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'No se pudo cargar el catálogo',
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      FilledButton(
                        onPressed: onRetry,
                        child: const Text('Reintentar'),
                      ),
                    ],
                  ),
                ),
              );
            }
            return child; // datos listos: la UI de Rol 2
        }
      },
    );
  }
}
