import 'dart:async';

import 'package:flutter/material.dart';

import '../../domain/usecases/seguir_entrega.dart';
import '../controllers/catalogo_controller.dart';
import 'catalogo_view.dart';

/// Pantalla de presentación (splash) de EcoMarket.
///
/// Muestra la marca con una animación de entrada y pasa al catálogo solo
/// después de [_entrada] (o cuando el usuario toca *Comenzar*).
///
/// Reglas de arquitectura respetadas:
/// * `Timer` y `AnimationController` se crean en **`initState`**, nunca en
///   `build()` → rotar el dispositivo no reinicia la animación ni el conteo.
/// * El `Timer` se cancela en `dispose()` → no hay navegación ni `setState`
///   después de salir de la pantalla.
/// * Sin colores hardcodeados: todo sale de `Theme.of(context).colorScheme`.
class PresentacionView extends StatefulWidget {
  final CatalogoController controller;
  final SeguirEntrega seguirEntrega;

  const PresentacionView({
    super.key,
    required this.controller,
    required this.seguirEntrega,
  });

  @override
  State<PresentacionView> createState() => _PresentacionViewState();
}

class _PresentacionViewState extends State<PresentacionView>
    with SingleTickerProviderStateMixin {
  /// Duración de la presentación antes de entrar al catálogo.
  static const Duration _entrada = Duration(milliseconds: 2800);

  late final Timer _auto;
  late final AnimationController _anim;

  /// Evita navegación doble (timer + botón) si ambos disparan.
  bool _entro = false;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..forward();
    _auto = Timer(_entrada, entrar);
  }

  /// Entra al catálogo. Idempotente: sirve para el timer y para el botón.
  void entrar() {
    if (_entro || !mounted) return;
    _entro = true;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (_) => CatalogoView(
          controller: widget.controller,
          seguirEntrega: widget.seguirEntrega,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _auto.cancel(); // sin navegación "fantasma" al salir
    _anim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final cs = t.colorScheme;

    return Scaffold(
      body: DecoratedBox(
        // Degradado sutil desde el verde ecológico hasta el fondo oscuro.
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [cs.primary.withValues(alpha: 0.16), Colors.transparent],
          ),
        ),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              // Compacto también en landscape bajo (891x411): menos alto.
              final compacto = constraints.maxWidth < 380 ||
                  constraints.maxHeight < 520;
              final padding = EdgeInsets.all(compacto ? 16 : 24);
              final icono = compacto ? 64.0 : 96.0;

              // Scroll + minHeight: centrado vertical en portrait y sin
              // overflow en horizontal ni con escala de fuente al 160 %.
              return SingleChildScrollView(
                child: ConstrainedBox(
                  constraints:
                      BoxConstraints(minHeight: constraints.maxHeight),
                  child: Center(
                    child: Padding(
                      padding: padding,
                      child: FadeTransition(
                        opacity: CurvedAnimation(
                          parent: _anim,
                          curve: Curves.easeOut,
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            ScaleTransition(
                              scale: CurvedAnimation(
                                parent: _anim,
                                curve: Curves.easeOutBack,
                              ),
                              child: Container(
                                width: icono + 32,
                                height: icono + 32,
                                decoration: BoxDecoration(
                                  color: cs.primaryContainer,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.eco,
                                  size: icono,
                                  color: cs.onPrimaryContainer,
                                ),
                              ),
                            ),
                            SizedBox(height: compacto ? 16 : 24),
                            // FittedBox: el nombre nunca desborda en 320 px
                            // ni con texto del sistema al 160 %.
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                'EcoMarket',
                                style: t.textTheme.displaySmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Compra verde · entrega limpia',
                              style: t.textTheme.titleMedium,
                              textAlign: TextAlign.center,
                            ),
                            SizedBox(height: compacto ? 24 : 32),
                            FilledButton.icon(
                              onPressed: entrar,
                              icon: const Icon(Icons.storefront),
                              label: const Text('Comenzar'),
                            ),
                            SizedBox(height: compacto ? 16 : 24),
                            // Barra de avance sincronizada con _entrada.
                            SizedBox(
                              width: 160,
                              child: TweenAnimationBuilder<double>(
                                tween: Tween(begin: 0, end: 1),
                                duration: _entrada,
                                curve: Curves.easeInOut,
                                builder: (context, v, _) =>
                                    LinearProgressIndicator(value: v),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
