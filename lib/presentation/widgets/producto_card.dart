import 'package:flutter/material.dart';

import '../../domain/entities/producto.dart';

/// Tarjeta de producto para el `SliverGrid` (proporción fija 0.65).
///
/// Como la proporción es fija, el contenido interno se flexibiliza con
/// `Expanded`, `maxLines` + `ellipsis` y `FittedBox` para no desbordar con
/// textos largos o fuentes grandes del sistema.
class ProductoCard extends StatelessWidget {
  final Producto producto;
  final VoidCallback onAgregar;

  const ProductoCard({
    super.key,
    required this.producto,
    required this.onAgregar,
  });

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // La imagen es la parte elástica: absorbe el espacio que sobra
          // (o cede el que falta) según el tamaño de la celda.
          Expanded(child: _Imagen(url: producto.imagenUrl)),
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  producto.nombre,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: t.textTheme.titleSmall,
                ),
                const SizedBox(height: 4),
                // Precio y stock en una sola línea elástica
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Flexible(
                      child: Text(
                        '\$${producto.precio.toStringAsFixed(2)}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: t.textTheme.titleMedium
                            ?.copyWith(color: t.colorScheme.primary),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        producto.agotado
                            ? 'Agotado'
                            : 'Stock: ${producto.stock}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: t.textTheme.bodySmall?.copyWith(
                          color: producto.agotado
                              ? t.colorScheme.error
                              : t.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.tonal(
                    onPressed: producto.agotado ? null : onAgregar,
                    style: FilledButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                    ),
                    child: const FittedBox(child: Text('Agregar')),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Imagen fluida con `loadingBuilder` y `errorBuilder`.
class _Imagen extends StatelessWidget {
  final String? url;
  const _Imagen({required this.url});

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).colorScheme;
    Widget placeholder(IconData icono) => ColoredBox(
          color: c.surfaceContainerHighest,
          child: Center(
            child: Icon(icono, size: 40, color: c.onSurfaceVariant),
          ),
        );

    final u = url; // promoción local: evita el operador "!"
    if (u == null) return placeholder(Icons.eco);

    return Image.network(
      u,
      fit: BoxFit.cover,
      loadingBuilder: (context, child, progreso) {
        if (progreso == null) return child;
        final totalBytes = progreso.expectedTotalBytes;
        return Center(
          child: CircularProgressIndicator(
            value: totalBytes == null
                ? null
                : progreso.cumulativeBytesLoaded / totalBytes,
          ),
        );
      },
      errorBuilder: (context, error, stack) => placeholder(Icons.broken_image),
    );
  }
}
