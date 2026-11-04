# EcoMarket App — Catálogo y Monitoreo de Entregas Sustentables

Aplicación Flutter con **Clean Architecture**, diseño **oscuro** y **responsive**.

## Integrantes y roles

| Rol | Responsabilidad | Entregables principales |
|---|---|---|
| **Rol 1 — Líder de Arquitectura y Datos** | Estructura de capas, estado en RAM, contratos | `lib/domain/`, `lib/data/`, `CatalogoController`, inyección, README |
| **Rol 2 — UI / Catálogo** | Vista de catálogo, tema Material 3 oscuro, responsive | `catalogo_view.dart`, `app_theme.dart` |
| **Rol 3 — Checkout** | Validadores, carrito y flujo de pago | `checkout_view.dart`, `validators.dart` |
| **Rol 4 — Sincronización** | Async: `Future` de 1 s y `Stream` de 3 s, seguimiento GPS | datasources, `entrega_repository_impl.dart`, `seguimiento_view.dart` |

## Cómo correr

```bash
flutter pub get
flutter run          # app en modo oscuro forzado
flutter analyze      # sin errores
flutter test         # 15 pruebas: asserts, atomicidad, notificación única
```

## Diagrama de capas

```
                    ┌──────────────────────────────┐
                    │        presentation/         │
                    │  widgets · views · controller│
                    └──────────────┬───────────────┘
                                   │ solo habla con domain
                                   ▼
┌──────────────────────────────────────────────────────────┐
│                        domain/                          │
│  entities (Producto, ItemCarrito, EstadoEntrega)        │
│  repositories (contratos abstractos)                    │
│  usecases (ObtenerCatalogo, ConfirmarCompra, Seguir…)    │
│                                                          │
│  Dart puro: SIN imports de flutter/material.dart         │
└──────────────▲───────────────────────────▲───────────────┘
               │ implementa los contratos  │
     ┌─────────┴─────────┐       ┌─────────┴──────────┐
     │       data/       │       │      core/         │
     │ datasources       │       │ di/  inyección     │
     │ models            │       │ theme/ tema oscuro │
     │ repositories (impl)│      │ utils/ validadores │
     └───────────────────┘       └────────────────────┘
```

**Regla de dependencias:** `presentation → domain ← data`
- `domain` no importa nada de `data`, `presentation` ni `flutter`.
- `data` implementa las interfaces de `domain`.
- `presentation` solo habla con `domain` (casos de uso / entidades).
- **Ningún widget** llama a un datasource ni calcula reglas de negocio.

Verificación:

```bash
grep -rn "package:flutter" lib/domain        # → 0 resultados
grep -rn "data/" lib/presentation            # → 0 resultados
```

## Decisiones de diseño

1. **Entidades inmutables con `assert`.** `Producto` valida `precio >= 0`,
   `stock >= 0` y `nombre != ''` en el constructor. Los `assert` solo corren
   en debug: `Producto(stock: -1)` lanza `AssertionError` en desarrollo.
   Además el controller **valida en runtime** antes de crear copias
   (`agregarAlCarrito`, `reabastecer`), nunca dependemos solo del assert.
2. **Inmutabilidad + `copyWith`.** Para "mutar" stock se crea una copia;
   ninguna capa modifica un objeto ya entregado.
3. **Repositorio abstracto.** `CatalogoRepository` y `EntregaRepository` son
   interfaces en `domain`; la implementación concreta vive en `data`. Si
   mañana cambiamos a una API real, SQLite o un mock, **solo se toca `data/`**.
4. **Casos de uso como única vía de regla de negocio.** `ConfirmarCompra`
   valida **todo** el carrito antes de descontar un solo stock (atomicidad):
   si algo falla, devuelve `ResultadoCompra.fallo` sin haber mutado nada.
5. **Un único `notifyListeners()` por operación.** `confirmarPago()` y
   `reabastecer()` notifican una sola vez → refresco atómico, sin parpadeo.
6. **Listas inmodificables hacia la UI.** `productos` y `carrito` exponen
   `List.unmodifiable`; la UI solo lee.
7. **Inyección manual** en `core/di/injection.dart`: `main()` decide qué
   implementación concreta recibe cada contrato. Sin frameworks de DI.
8. **Getter/setter computados:** `agotado`, `subtotal`, `total`, `totalItems`,
   `productosVisibles` y `categoriaActiva` se derivan del estado; nunca se
   guardan duplicados (evita desincronización).
9. **Datos semilla en `ProductoModel`:** 9 productos, 4 categorías
   (Hogar, Higiene, Alimentos, Accesorios), uno con `stock: 1` y otro con
   `stock: 0` para prueba de estrés, y dos con `imagenUrl: null` para
   demostrar el `errorBuilder`.

## Estructura de carpetas

```
lib/
├── main.dart                     # composición / inyección manual (Rol 1)
├── core/
│   ├── di/injection.dart
│   ├── theme/app_theme.dart
│   └── utils/validators.dart
├── domain/                       # Dart puro: SIN flutter/material.dart
│   ├── entities/                 # Producto, ItemCarrito, EstadoEntrega
│   ├── repositories/             # contratos abstractos
│   └── usecases/                 # ObtenerCatalogo, ConfirmarCompra, SeguirEntrega
├── data/
│   ├── datasources/              # fuente remota (Future 1 s) y GPS (Stream 3 s)
│   ├── models/                   # ProductoModel (+ datos semilla)
│   └── repositories/             # implementaciones de los contratos
└── presentation/
    ├── controllers/              # CatalogoController (estado en RAM)
    ├── views/                    # catalogo, checkout, seguimiento
    └── widgets/
```
