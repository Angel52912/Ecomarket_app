# ROL 4 — Ingeniero de Sincronización Asíncrona (Backend/Async Specialist)

**Proyecto:** EcoMarket App — Catálogo y Monitoreo de Entregas Sustentables
**Sprint:** comprimido a **1 solo día**
**Restricciones globales:** Clean Architecture · diseño **oscuro** · **responsive** · prohibido mezclar código de capas

---

## 1. Misión

Simulas el "backend": un `Future` que tarda 1 segundo en entregar el catálogo y un `Stream` que emite la posición GPS del repartidor cada 3 segundos. Los conectas a la UI **solo** mediante `FutureBuilder` y `StreamBuilder`, manejando siempre los estados de carga, error y datos, para que la app nunca se congele.

| Responsabilidad | Entregable |
|---|---|
| Datasource de catálogo (Future, 1 s) | `data/datasources/catalogo_remote_datasource.dart` |
| Datasource GPS (Stream, 3 s por ciclo) | `data/datasources/entrega_gps_datasource.dart` |
| Implementación del repo de entrega | `data/repositories/entrega_repository_impl.dart` |
| Compuerta de carga del catálogo | `presentation/widgets/catalogo_future_gate.dart` (`FutureBuilder`) |
| Vista de seguimiento | `presentation/views/seguimiento_view.dart` (`StreamBuilder`) |

> El `CatalogoRepositoryImpl` y el `ProductoModel` los escribe el Rol 1; tú le entregas el datasource que devuelve los modelos.

---

## 2. Qué NO haces (capas)

- ❌ Los widgets no crean `Future.delayed` ni `Stream` propios: reciben el `Future`/`Stream` desde `domain`/`data`.
- ❌ `data/` no importa `material.dart` (los datasources son Dart puro).
- ✅ Dependes de las interfaces de `domain`: `CatalogoRepository`, `EntregaRepository`, `EstadoEntrega` (las crea el Rol 1 en el Bloque 1).

---

## 3. Plan de trabajo en UN día

| Bloque | Duración | Tu trabajo |
|---|---|---|
| **B1 – Esqueleto** | 0:00 – 1:00 | Leer los contratos del Rol 1; crear los archivos de datasource con datos semilla; probar el Future/Stream en consola |
| **B2 – Servicios** | 1:00 – 3:00 | Datasource de catálogo (1 s), Stream GPS (3 s), `EntregaRepositoryImpl`, `CatalogoFutureGate` |
| **B3 – Integración** | 3:00 – 5:00 | `SeguimientoView` con `StreamBuilder`; conectar con el flujo de checkout; manejar estados loading/error/done |
| **B4 – QA** | 5:00 – 6:00 | Cancelación de streams, rotación/pausa, tiempos reales, tema oscuro y responsive en Seguimiento |

---

## 4. Paso a paso

### B2.1 Datasource de catálogo: `Future` con retardo de 1 s

`lib/data/datasources/catalogo_remote_datasource.dart`

```dart
class CatalogoRemoteDataSource {
  /// Simula una llamada de red.
  Future<List<ProductoModel>> fetchProductos() async {
    await Future.delayed(const Duration(seconds: 1)); // retardo de red simulado
    return _semilla;
  }

  // Mínimo 8 productos: uno con stock 1, uno con stock 0, uno sin imagen
  static const List<ProductoModel> _semilla = [
    ProductoModel(id: 'p1', nombre: 'Botella reutilizable de acero', categoria: 'Hogar', precio: 249.0, stock: 12, imagenUrl: 'https://picsum.photos/seed/botella/400/500'),
    ProductoModel(id: 'p2', nombre: 'Cepillo de bambú (pack 4)', categoria: 'Higiene', precio: 99.0, stock: 20, imagenUrl: 'https://picsum.photos/seed/cepillo/400/500'),
    ProductoModel(id: 'p3', nombre: 'Bolsas de tela orgánica', categoria: 'Accesorios', precio: 129.0, stock: 1, imagenUrl: 'https://picsum.photos/seed/bolsas/400/500'),
    ProductoModel(id: 'p4', nombre: 'Jabón artesanal de avena', categoria: 'Higiene', precio: 59.0, stock: 0, imagenUrl: 'https://picsum.photos/seed/jabon/400/500'),
    ProductoModel(id: 'p5', nombre: 'Granola orgánica 500 g', categoria: 'Alimentos', precio: 89.0, stock: 15, imagenUrl: null),
    ProductoModel(id: 'p6', nombre: 'Popotes de vidrio (set)', categoria: 'Hogar', precio: 79.0, stock: 8, imagenUrl: 'https://url-invalida.example/img.png'), // fuerza errorBuilder
    ProductoModel(id: 'p7', nombre: 'Café de altura molido', categoria: 'Alimentos', precio: 159.0, stock: 6, imagenUrl: 'https://picsum.photos/seed/cafe/400/500'),
    ProductoModel(id: 'p8', nombre: 'Lonchera de acero inoxidable', categoria: 'Accesorios', precio: 319.0, stock: 4, imagenUrl: 'https://picsum.photos/seed/lonchera/400/500'),
  ];
}
```

> Esto implica que `ProductoModel` extiende/convierte a `Producto` (Rol 1) y tiene constructor `const`. Coordina con el Rol 1 si la semilla se define aquí o en el repo.

### B2.2 Datasource GPS: `Stream` con pausa de 3 s por ciclo

`lib/data/datasources/entrega_gps_datasource.dart`

```dart
class EntregaGpsDataSource {
  // Ruta simulada (lat, lng) de punta a punta
  static const _ruta = <(double, double)>[
    (20.9754, -89.6170), (20.9731, -89.6139), (20.9702, -89.6101),
    (20.9680, -89.6062), (20.9655, -89.6030), (20.9630, -89.5998),
  ];

  /// Emite un estado cada 3 s; los minutos bajan 1 por ciclo hasta 0.
  Stream<EstadoEntrega> rastrear({int minutosIniciales = 5}) async* {
    var minutos = minutosIniciales;
    var paso = 0;
    while (minutos >= 0) {
      await Future.delayed(const Duration(seconds: 3)); // pausa realista
      final (lat, lng) = _ruta[paso.clamp(0, _ruta.length - 1)];
      yield EstadoEntrega(
        minutosRestantes: minutos,
        latitud: lat,
        longitud: lng,
        mensaje: minutos == 0 ? '¡Tu pedido llegó!' : 'Tu repartidor va en camino',
      );
      minutos--;
      paso++;
    }
    // Al terminar el while, el stream se cierra solo (ConnectionState.done)
  }
}
```

> Los *records* `(double, double)` requieren Dart 3. Si tu SDK es anterior, usa una lista de `List<double>`.

### B2.3 Repositorio de entrega (implementa el contrato del dominio)

```dart
class EntregaRepositoryImpl implements EntregaRepository {
  final EntregaGpsDataSource _gps;
  const EntregaRepositoryImpl(this._gps);

  @override
  Stream<EstadoEntrega> seguirEntrega() => _gps.rastrear();
}
```

Y el repositorio de catálogo (Rol 1) usa `CatalogoRemoteDataSource.fetchProductos()`.

### B2.4 `CatalogoFutureGate`: `FutureBuilder` con loading / error / datos

`lib/presentation/widgets/catalogo_future_gate.dart`

```dart
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
                      Icon(Icons.cloud_off, size: 48, color: Theme.of(context).colorScheme.error),
                      const SizedBox(height: 12),
                      Text('No se pudo cargar el catálogo', textAlign: TextAlign.center),
                      const SizedBox(height: 12),
                      FilledButton(onPressed: onRetry, child: const Text('Reintentar')),
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
```

**Detalle importante (error común que baja la nota):** si creas el `Future` dentro de `build()`, cada redibujo relanza la petición (y se "fuerza el redibujado"). Por eso el `Future` vive en `late final` / `initState`.

**Reintentar:** `onRetry` debe crear un nuevo `Future` en el `State` (en `CatalogoView`: `setState(() => _carga = widget.controller.cargarCatalogo())`, declarando `_carga` como `late Future<void>` no-final). Acuerda este ajuste con el Rol 2.

### B3.1 `SeguimientoView`: `StreamBuilder`

`lib/presentation/views/seguimiento_view.dart`

```dart
class SeguimientoView extends StatefulWidget {
  final SeguirEntrega seguirEntrega;
  const SeguimientoView({super.key, required this.seguirEntrega});

  @override
  State<SeguimientoView> createState() => _SeguimientoViewState();
}

class _SeguimientoViewState extends State<SeguimientoView> {
  // Se crea UNA sola vez: reconstruir la vista no reinicia el reloj
  late final Stream<EstadoEntrega> _stream = widget.seguirEntrega();

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Seguimiento de entrega')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: StreamBuilder<EstadoEntrega>(
            stream: _stream,
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return const Text('Se perdió la señal del GPS');
              }
              final estado = snapshot.data; // EstadoEntrega? (nulo hasta el primer evento)
              if (estado == null) {
                return const Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Conectando con el repartidor…'),
                  ],
                );
              }
              return Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(estado.llego ? Icons.check_circle : Icons.delivery_dining,
                        size: 72, color: t.colorScheme.primary),
                    const SizedBox(height: 16),
                    Text(estado.mensaje, style: t.textTheme.titleLarge, textAlign: TextAlign.center),
                    const SizedBox(height: 8),
                    Text(
                      estado.llego ? 'Entregado' : '${estado.minutosRestantes} min restantes',
                      style: t.textTheme.displaySmall,
                    ),
                    const SizedBox(height: 16),
                    // Wrap evita overflow de las coordenadas en pantallas angostas
                    Wrap(
                      spacing: 12,
                      runSpacing: 8,
                      alignment: WrapAlignment.center,
                      children: [
                        Chip(label: Text('Lat ${estado.latitud.toStringAsFixed(4)}')),
                        Chip(label: Text('Lng ${estado.longitud.toStringAsFixed(4)}')),
                      ],
                    ),
                    if (snapshot.connectionState == ConnectionState.done) ...[
                      const SizedBox(height: 24),
                      FilledButton(
                        onPressed: () => Navigator.of(context).popUntil((r) => r.isFirst),
                        child: const Text('Volver al catálogo'),
                      ),
                    ],
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
```

**Cancelación automática:** `StreamBuilder` cancela su suscripción al salir de la vista. Aun así, comprueba en pruebas que al volver atrás **no** siguen llegando eventos.

---

## 5. Sincronización "descuento de minutos" (defensa en vivo)

El docente revisará que el reloj GPS descuente los minutos **de forma sincronizada**. Para que sea convincente:

- Un solo `Stream` fuente de verdad: minutos, coordenadas y mensaje salen del **mismo** `EstadoEntrega` en cada evento (no uses dos timers separados).
- Cada ciclo es de 3 s reales; con `minutosIniciales: 5` el recorrido total dura ≈ 18 s, ideal para la demo. Puedes ajustarlo, pero conserva los 3 s por ciclo.
- Mantén el hilo de UI libre: nada de `sleep()` ni bucles síncronos; solo `await Future.delayed`. Comprueba que el catálogo **se puede tocar y hacer scroll** mientras carga.

---

## 6. Pruebas manuales (B4)

- [ ] Al abrir la app: indicador de carga ≈ 1 s y luego aparece el catálogo
- [ ] Forzar error (lanza `throw Exception()` en el datasource) → pantalla de error con **Reintentar**; restaurar y verificar que reintenta
- [ ] Imagen con URL inválida (`p6`) → icono con `errorBuilder`, no crash
- [ ] Tras pagar, Seguimiento muestra "Conectando…" ≈ 3 s y luego baja los minutos cada 3 s
- [ ] Al llegar a 0: mensaje "¡Tu pedido llegó!" y botón para volver
- [ ] Salir de Seguimiento a mitad del recorrido → no hay errores ni `setState() called after dispose`
- [ ] Rotar el dispositivo durante el Stream → el reloj **no se reinicia**
- [ ] La UI no se congela en ningún momento (scroll fluido en el catálogo durante la carga)
- [ ] Vista de seguimiento en modo oscuro y sin overflow en 320 px

## 7. Convención de commits

```
feat(rol4): datasource de catalogo con Future.delayed de 1 s
feat(rol4): datasource GPS con Stream async* y pausa de 3 s
feat(rol4): EntregaRepositoryImpl implementa el contrato del dominio
feat(rol4): CatalogoFutureGate con FutureBuilder (loading/error/data)
feat(rol4): SeguimientoView con StreamBuilder y estado done
fix(rol4): Future/Stream creados una sola vez fuera de build
```

## 8. Rúbrica que te evalúa (Sincronización Reactiva)

| Nivel | Condición |
|---|---|
| **10** | Futures/Streams con Builders dedicados; interfaz libre de congelamiento |
| 8 | Asincronía básica sin control de loading/error en el snapshot, o redibujado forzado |
| 5 | La pantalla se congela en consultas o la app es cerrada por el SO |

**Preguntas probables en la defensa:** ¿diferencia entre `Future` y `Stream`? · ¿qué es `async*` y `yield`? · ¿por qué no se crea el `Future` dentro de `build()`? · ¿qué `ConnectionState` hay en `StreamBuilder` y cuándo es `done`? · ¿qué pasa si el usuario sale de la pantalla mientras el Stream emite?
