import 'package:flutter/material.dart';

/// Filtros de categoría. Usa [Wrap] (no `Row`) para que, si hay muchas
/// categorías o la pantalla es angosta, los chips salten de línea en vez de
/// provocar RenderFlex overflow.
class CategoriasWrap extends StatelessWidget {
  final List<String> categorias;
  final String? activa;
  final ValueChanged<String?> onSeleccion;

  const CategoriasWrap({
    super.key,
    required this.categorias,
    required this.activa,
    required this.onSeleccion,
  });

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
        child: Wrap(
          spacing: 8, // separación horizontal
          runSpacing: 8, // separación entre líneas
          children: [
            ChoiceChip(
              label: const Text('Todas'),
              selected: activa == null,
              onSelected: (_) => onSeleccion(null),
            ),
            for (final c in categorias)
              ChoiceChip(
                label: Text(c),
                selected: activa == c,
                onSelected: (_) => onSeleccion(c),
              ),
          ],
        ),
      );
}
