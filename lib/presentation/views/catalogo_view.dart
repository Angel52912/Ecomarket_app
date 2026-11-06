import 'package:flutter/material.dart';

import '../../domain/usecases/seguir_entrega.dart';
import '../controllers/catalogo_controller.dart';
import '../widgets/catalogo_future_gate.dart';
import '../widgets/categorias_wrap.dart';
import '../widgets/producto_card.dart';
import 'seguimiento_view.dart';

/// Pantalla principal del catálogo (Rol 2).
///
/// Un **solo scroll** (`CustomScrollView`) con `SliverAppBar` fijo, chips en
/// `Wrap` y un `SliverGrid` responsivo. La vista no contiene lógica de
/// negocio: solo lee el `CatalogoController` y le manda mensajes.
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
  // ⚠️ El Future se crea UNA sola vez, fuera de `build()` (Rol 4).
  // No es `final` porque `onRetry` lo reemplaza con uno nuevo.
  late Future<void> _carga = widget.controller.cargarCatalogo();

  void _reintentar() {
    setState(() => _carga = widget.controller.cargarCatalogo());
  }

  void _reabastecer() {
    widget.controller.reabastecer();
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(const SnackBar(content: Text('Stock rellenado')));
  }

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
                pinned: true, // la barra queda fija al hacer scroll
                expandedHeight: 140,
                actions: [
                  IconButton(
                    tooltip: 'Seguimiento de entrega',
                    icon: const Icon(Icons.delivery_dining),
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => SeguimientoView(
                          seguirEntrega: widget.seguirEntrega,
                        ),
                      ),
                    ),
                  ),
                  _CarritoAction(controller: c),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  title: const Text('EcoMarket'),
                  titlePadding:
                      const EdgeInsetsDirectional.only(start: 16, bottom: 14),
                  background: Align(
                    alignment: AlignmentDirectional.bottomStart,
                    child: Padding(
                      padding: const EdgeInsetsDirectional.only(
                        start: 16,
                        bottom: 52,
                      ),
                      child: Text(
                        'Productos sustentables',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
                            ),
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
              if (c.productosVisibles.isEmpty)
                const SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(child: Text('Sin productos disponibles')),
                )
              else
                _GridProductos(controller: c),
              // Espacio para que el FAB no tape la última fila
              const SliverToBoxAdapter(child: SizedBox(height: 96)),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _reabastecer,
        icon: const Icon(Icons.inventory_2),
        label: const Text('Rellenar Stock'),
      ),
    );
  }
}

/// `SliverGrid` responsivo: `childAspectRatio` fijo en 0.65 (ancho/alto) y
/// número de columnas según el ancho real del viewport.
class _GridProductos extends StatelessWidget {
  final CatalogoController controller;
  const _GridProductos({required this.controller});

  static int columnas(double ancho) {
    if (ancho >= 1200) return 5;
    if (ancho >= 900) return 4;
    if (ancho >= 600) return 3;
    return 2; // teléfonos
  }

  void _agregar(BuildContext context, int i) {
    final productos = controller.productosVisibles;
    final error = controller.agregarAlCarrito(productos[i]);
    if (error == null) return;
    final cs = Theme.of(context).colorScheme;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Text(error, style: TextStyle(color: cs.onErrorContainer)),
        backgroundColor: cs.errorContainer,
      ));
  }

  @override
  Widget build(BuildContext context) {
    final productos = controller.productosVisibles;
    // SliverLayoutBuilder da el ancho real disponible dentro del sliver
    return SliverLayoutBuilder(
      builder: (context, constraints) => SliverPadding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        sliver: SliverGrid(
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columnas(constraints.crossAxisExtent),
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 0.65,
          ),
          // "Bajo demanda": solo se construyen las tarjetas visibles
          delegate: SliverChildBuilderDelegate(
            (context, i) => ProductoCard(
              producto: productos[i],
              onAgregar: () => _agregar(context, i),
            ),
            childCount: productos.length,
          ),
        ),
      ),
    );
  }
}

/// Icono del carrito con `Badge` reactivo (cantidad de artículos).
///
/// TODO(rol3): al existir `CheckoutView`, reemplazar el SnackBar por:
/// `Navigator.push(MaterialPageRoute(builder: (_) => CheckoutView(...)))`.
class _CarritoAction extends StatelessWidget {
  final CatalogoController controller;
  const _CarritoAction({required this.controller});

  @override
  Widget build(BuildContext context) => IconButton(
        tooltip: 'Carrito',
        icon: Badge(
          isLabelVisible: controller.totalItems > 0,
          label: Text('${controller.totalItems}'),
          child: const Icon(Icons.shopping_cart_outlined),
        ),
        onPressed: () => ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(
            content: Text(
              'Carrito: ${controller.totalItems} artículo(s) · '
              'Total \$${controller.total.toStringAsFixed(2)}',
            ),
          )),
      );
}
