import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/utils/validators.dart';
import '../../domain/usecases/seguir_entrega.dart';
import '../controllers/catalogo_controller.dart';
import 'seguimiento_view.dart';

/// Vista de checkout (Rol 3).
///
/// Un solo `Form` coordinado por una `GlobalKey<FormState>`: `validate()`
/// recorre **todos** los `TextFormField` a la vez y los pinta en rojo.
/// La vista no calcula totales ni toca el stock: usa `controller.total` y
/// `controller.confirmarPago()` (Rol 1).
class CheckoutView extends StatefulWidget {
  final CatalogoController controller;
  final SeguirEntrega seguirEntrega;

  const CheckoutView({
    super.key,
    required this.controller,
    required this.seguirEntrega,
  });

  @override
  State<CheckoutView> createState() => _CheckoutViewState();
}

class _CheckoutViewState extends State<CheckoutView> {
  // La llave de alta jerarquía: valida TODOS los campos de un solo golpe.
  final _formKey = GlobalKey<FormState>();
  bool _procesando = false;

  Future<void> _pagar() async {
    if (_procesando) return; // evita el doble toque
    final valido = _formKey.currentState?.validate() ?? false; // sin "!"
    if (!valido) return; // los TextFormField ya se pintan en rojo solos

    setState(() => _procesando = true);
    // Rol 1: resta stock y vacía el carrito de forma atómica.
    final error = widget.controller.confirmarPago();
    if (!mounted) return;
    setState(() => _procesando = false);

    if (error != null) {
      final cs = Theme.of(context).colorScheme;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(
          content: Text(error, style: TextStyle(color: cs.onErrorContainer)),
          backgroundColor: cs.errorContainer,
          action: SnackBarAction(
            label: 'Rellenar Stock',
            textColor: cs.onErrorContainer,
            onPressed: widget.controller.reabastecer, // refresco atómico
          ),
        ));
      return;
    }

    // Cierre del flujo: no se puede "volver" a pagar el mismo carrito.
    Navigator.of(context).pushReplacement(MaterialPageRoute<void>(
      builder: (_) => SeguimientoView(seguirEntrega: widget.seguirEntrega),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.controller;
    return Scaffold(
      appBar: AppBar(title: const Text('Checkout')),
      body: ListenableBuilder(
        listenable: c,
        builder: (context, _) {
          if (c.carrito.isEmpty) {
            return const Center(child: Text('Tu carrito está vacío'));
          }
          return Center(
            // Limita el ancho en tablets/escritorio: el formulario no se estira
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 640),
              // El scroll evita el overflow cuando aparece el teclado
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _ResumenPedido(controller: c),
                    const SizedBox(height: 24),
                    _formulario(),
                    const SizedBox(height: 24),
                    FilledButton.icon(
                      onPressed: _procesando ? null : _pagar,
                      icon: _procesando
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.lock_outline),
                      label: Text('Pagar \$${c.total.toStringAsFixed(2)}'),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _formulario() => Form(
        key: _formKey,
        // Alertas rojas reactivas: tras tocar un campo se revalida al escribir
        autovalidateMode: AutovalidateMode.onUserInteraction,
        child: Column(
          children: [
            TextFormField(
              decoration: const InputDecoration(
                labelText: 'Nombre completo',
                prefixIcon: Icon(Icons.person_outline),
              ),
              textInputAction: TextInputAction.next,
              keyboardType: TextInputType.name,
              textCapitalization: TextCapitalization.words,
              validator: Validators.nombre,
            ),
            const SizedBox(height: 16),
            TextFormField(
              decoration: const InputDecoration(
                labelText: 'Correo electrónico',
                prefixIcon: Icon(Icons.mail_outline),
              ),
              textInputAction: TextInputAction.next,
              keyboardType: TextInputType.emailAddress,
              autocorrect: false,
              validator: Validators.correo,
            ),
            const SizedBox(height: 16),
            TextFormField(
              decoration: const InputDecoration(
                labelText: 'Teléfono (10 dígitos)',
                prefixIcon: Icon(Icons.phone_outlined),
              ),
              textInputAction: TextInputAction.next,
              keyboardType: TextInputType.phone,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(10),
              ],
              validator: Validators.telefono,
            ),
            const SizedBox(height: 16),
            TextFormField(
              decoration: const InputDecoration(
                labelText: 'Dirección de entrega',
                prefixIcon: Icon(Icons.home_outlined),
              ),
              textInputAction: TextInputAction.next,
              keyboardType: TextInputType.streetAddress,
              validator: Validators.direccion,
            ),
            const SizedBox(height: 16),
            TextFormField(
              decoration: const InputDecoration(
                labelText: 'Código postal',
                prefixIcon: Icon(Icons.markunread_mailbox_outlined),
              ),
              textInputAction: TextInputAction.done,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(5),
              ],
              validator: Validators.codigoPostal,
              onFieldSubmitted: (_) => _pagar(),
            ),
          ],
        ),
      );
}

/// Resumen del pedido: solo presentación, los números vienen del controller.
class _ResumenPedido extends StatelessWidget {
  final CatalogoController controller;
  const _ResumenPedido({required this.controller});

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Resumen del pedido', style: t.textTheme.titleMedium),
            const Divider(height: 24),
            for (final i in controller.carrito)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${i.cantidad} × ${i.producto.nombre}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text('\$${i.subtotal.toStringAsFixed(2)}'),
                    IconButton(
                      tooltip: 'Quitar',
                      icon: const Icon(Icons.close, size: 18),
                      onPressed: () =>
                          controller.quitarDelCarrito(i.producto.id),
                    ),
                  ],
                ),
              ),
            const Divider(height: 24),
            Row(
              children: [
                Expanded(
                  child: Text('Total', style: t.textTheme.titleMedium),
                ),
                Text(
                  '\$${controller.total.toStringAsFixed(2)}',
                  style: t.textTheme.titleLarge
                      ?.copyWith(color: t.colorScheme.primary),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
