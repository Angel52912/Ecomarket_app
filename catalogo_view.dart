import 'package:flutter/material.dart';

import '../../domain/usecases/seguir_entrega.dart';
import '../controllers/catalogo_controller.dart';
import '../widgets/catalogo_future_gate.dart';
import '../widgets/categorias_wrap.dart';
import '../widgets/producto_card.dart';
import 'checkout_view.dart';

/// Pantalla principal. SOLO pinta lo que expone [CatalogoController]:
/// no calcula totales ni descuenta stock.
///
/// Un único scroll ([CustomScrollView]) para toda la pantalla; nunca un
/// GridView dentro de un ListView (colisión de scrolls).
class CatalogoView extends StatefulWidget {
  final CatalogoController controller;
  final SeguirEntrega seguirEntrega;

  const CatalogoView({
    super.key,
    required this.controller,
    required this.seguirEntrega,
  });

  @override
  State<CatalogoView> createState() => _CatalogoViewState();
}

class _CatalogoViewState extends State<CatalogoView> {
  // El Future se crea fuera de build() (initState / reintento), nunca dentro.
  late Future<void> _carga = widget.controller.cargarCatalogo();

  void _reintentar() => setState(() {
        _carga = widget.controller.cargarCatalogo();
      });

  @override
  Widget build(BuildContext context) {
    final c = widget.controller;
    return Scaffold(
      body: CatalogoFutureGate(
        future: _carga,
        onRetry: _reintentar,
        child: ListenableBuilder(
          listenable: c,
          builder: (context, _) => CustomScrollView(
            slivers: [
              SliverAppBar(
                pinned: true,
                expandedHeight: 140,
                title: const Text('EcoMarket'),
                actions: [
                  _CarritoAction(
                    controller: c,
                    seguirEntrega: widget.seguirEntrega,
                  ),
                ],
                flexibleSpace: const FlexibleSpaceBar(
                  collapseMode: CollapseMode.parallax,
                  background: Align(
                    alignment: AlignmentDirectional.bottomStart,
                    child: Padding(
                      padding: EdgeInsetsDirectional.only(start: 16, bottom: 14),
                      child: Text(
                        'Productos sustentables',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: CategoriasWrap(
                  categorias: c.categorias,
                  activa: c.categoriaActiva,
                  onSeleccion: (v) => c.categoriaActiva = v,
                ),
              ),
              _GridProductos(controller: c),
              // Espacio para que el FAB no tape la última fila.
              const SliverToBoxAdapter(child: SizedBox(height: 96)),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          c.reabastecer();
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(const SnackBar(content: Text('Stock rellenado')));
        },
        icon: const Icon(Icons.inventory_2),
        label: const Text('Rellenar Stock'),
      ),
    );
  }
}

/// Grid responsivo: `childAspectRatio` fijo en 0.65 (ancho / alto);
/// lo que varía es CUÁNTAS columnas caben según el ancho disponible.
class _GridProductos extends StatelessWidget {
  final CatalogoController controller;
  const _GridProductos({required this.controller});

  int _columnas(double ancho) {
    if (ancho >= 1200) return 5;
    if (ancho >= 900) return 4;
    if (ancho >= 600) return 3;
    return 2; // teléfonos
  }

  @override
  Widget build(BuildContext context) {
    final productos = controller.productosVisibles;

    if (productos.isEmpty) {
      return const SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Center(child: Text('No hay productos en esta categoría')),
        ),
      );
    }

    // SliverLayoutBuilder entrega el ancho real del viewport dentro de un sliver.
    return SliverLayoutBuilder(
      builder: (context, constraints) => SliverPadding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        sliver: SliverGrid(
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: _columnas(constraints.crossAxisExtent),
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 0.65,
          ),
          // "Bajo demanda": solo se construyen las tarjetas visibles.
          delegate: SliverChildBuilderDelegate(
            (context, i) => ProductoCard(
              producto: productos[i],
              onAgregar: () {
                final error = controller.agregarAlCarrito(productos[i]);
                if (error != null) {
                  ScaffoldMessenger.of(context)
                    ..hideCurrentSnackBar()
                    ..showSnackBar(SnackBar(
                      content: Text(error),
                      backgroundColor:
                          Theme.of(context).colorScheme.errorContainer,
                    ));
                }
              },
            ),
            childCount: productos.length,
          ),
        ),
      ),
    );
  }
}

class _CarritoAction extends StatelessWidget {
  final CatalogoController controller;
  final SeguirEntrega seguirEntrega;

  const _CarritoAction({
    required this.controller,
    required this.seguirEntrega,
  });

  @override
  Widget build(BuildContext context) => IconButton(
        tooltip: 'Carrito',
        icon: Badge(
          isLabelVisible: controller.totalItems > 0,
          label: Text('${controller.totalItems}'),
          child: const Icon(Icons.shopping_cart_outlined),
        ),
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => CheckoutView(
              controller: controller,
              seguirEntrega: seguirEntrega,
            ),
          ),
        ),
      );
}
