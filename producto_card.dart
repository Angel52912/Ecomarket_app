import 'package:flutter/material.dart';

import '../../domain/entities/producto.dart';

/// Tarjeta de producto pensada para vivir dentro de un grid con
/// `childAspectRatio` FIJO (0.65). Por eso su contenido es elástico:
///  - la imagen y la info se reparten el alto con [Expanded] (flex 4 / 5),
///  - la info se encoge con [FittedBox.scaleDown] si el espacio no alcanza
///    (textos largos, fuente del sistema al 150-200 %, pantallas de 320 px).
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
          Expanded(flex: 4, child: _Imagen(url: producto.imagenUrl)),
          Expanded(
            flex: 5,
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: LayoutBuilder(
                builder: (context, constraints) => FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.topLeft,
                  child: SizedBox(
                    width: constraints.maxWidth,
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
                        const SizedBox(height: 2),
                        Text(
                          '\$${producto.precio.toStringAsFixed(2)}',
                          style: t.textTheme.titleMedium
                              ?.copyWith(color: t.colorScheme.primary),
                        ),
                        Text(
                          producto.agotado
                              ? 'Agotado'
                              : 'Stock: ${producto.stock}',
                          style: t.textTheme.bodySmall?.copyWith(
                            color: producto.agotado ? t.colorScheme.error : null,
                          ),
                        ),
                        const SizedBox(height: 8),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton.tonal(
                            onPressed: producto.agotado ? null : onAgregar,
                            child: const Text('Agregar'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Imagen extends StatelessWidget {
  final String? url;
  const _Imagen({required this.url});

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).colorScheme;

    Widget placeholder(IconData icono) => ColoredBox(
          color: c.surfaceContainerHighest,
          child: Center(child: Icon(icono, size: 40, color: c.onSurfaceVariant)),
        );

    final u = url; // promoción local: evita el operador "!"
    if (u == null) return placeholder(Icons.eco);

    return Image.network(
      u,
      fit: BoxFit.cover,
      loadingBuilder: (context, child, progreso) => progreso == null
          ? child
          : Center(
              child: CircularProgressIndicator(
                value: progreso.expectedTotalBytes == null
                    ? null
                    : progreso.cumulativeBytesLoaded /
                        progreso.expectedTotalBytes!,
              ),
            ),
      errorBuilder: (context, error, stack) => placeholder(Icons.broken_image),
    );
  }
}
