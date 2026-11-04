// NOTA (Rol 1 → coordinado con Rol 4): esta vista sigue siendo un stub del
// Rol 2. El Rol 4 integró aquí el `CatalogoFutureGate` (B2.4) y un puente
// temporal hacia `SeguimientoView`, porque el checkout real es del Rol 3.
import 'package:flutter/material.dart';

import '../../domain/usecases/seguir_entrega.dart';
import '../controllers/catalogo_controller.dart';
import '../views/seguimiento_view.dart';
import '../widgets/catalogo_future_gate.dart';

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
  // ⚠️ El Future se crea UNA sola vez, fuera de `build()`.
  // Si se creara dentro de build(), cada redibujado relanzaría la petición.
  // No es `final` precisamente porque `onRetry` lo reemplaza con uno nuevo.
  late Future<void> _carga = widget.controller.cargarCatalogo();

  void _reintentar() {
    setState(() => _carga = widget.controller.cargarCatalogo());
  }

  void _verSeguimiento() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => SeguimientoView(seguirEntrega: widget.seguirEntrega),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('EcoMarket'),
        // Puente temporal hasta que el Rol 3 conecte el pago real.
        actions: [
          IconButton(
            tooltip: 'Seguimiento de entrega',
            onPressed: _verSeguimiento,
            icon: const Icon(Icons.delivery_dining),
          ),
        ],
      ),
      // La compuerta maneja carga / error / datos; el catálogo nunca
      // bloquea el hilo de UI (el retardo vive en el datasource).
      body: CatalogoFutureGate(
        future: _carga,
        onRetry: _reintentar,
        child: ListenableBuilder(
          listenable: widget.controller,
          builder: (context, _) {
            final visibles = widget.controller.productosVisibles;
            if (visibles.isEmpty) {
              return const Center(child: Text('Sin productos disponibles'));
            }
            return ListView.builder(
              itemCount: visibles.length,
              itemBuilder: (context, i) {
                final p = visibles[i];
                return ListTile(
                  title: Text(p.nombre),
                  subtitle: Text('${p.categoria} · \$${p.precio}'),
                  trailing: Text(p.agotado ? 'Agotado' : 'Stock: ${p.stock}'),
                );
              },
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: widget.controller.reabastecer,
        child: const Icon(Icons.refresh),
      ),
    );
  }
}
