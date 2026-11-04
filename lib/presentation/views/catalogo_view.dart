// NOTA (Rol 1): stub mínimo para desbloquear `flutter analyze` y la demo.
// El Rol 2 debe reemplazarlo por la vista de catálogo responsive y oscura.
import 'package:flutter/material.dart';

import '../../domain/usecases/seguir_entrega.dart';
import '../controllers/catalogo_controller.dart';

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
  // La carga se dispara UNA sola vez; el refresco lo gobierna notifyListeners.
  @override
  void initState() {
    super.initState();
    widget.controller.cargarCatalogo();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('EcoMarket')),
      body: ListenableBuilder(
        listenable: widget.controller,
        builder: (context, _) {
          if (widget.controller.productos.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }
          return ListView.builder(
            itemCount: widget.controller.productosVisibles.length,
            itemBuilder: (context, i) {
              final p = widget.controller.productosVisibles[i];
              return ListTile(
                title: Text(p.nombre),
                subtitle: Text('${p.categoria} · \$${p.precio}'),
                trailing: Text(p.agotado ? 'Agotado' : 'Stock: ${p.stock}'),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: widget.controller.reabastecer,
        child: const Icon(Icons.refresh),
      ),
    );
  }
}
