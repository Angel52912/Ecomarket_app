# ROL 1 — Líder de Arquitectura y Datos (Domain/Data Specialist)

**Proyecto:** EcoMarket App — Catálogo y Monitoreo de Entregas Sustentables
**Sprint:** comprimido a **1 solo día** (en el documento original son 3)
**Restricciones globales:** Clean Architecture · diseño **oscuro** · **responsive** · prohibido mezclar código de capas

---

## 1. Misión

Eres el dueño de la **estructura del proyecto** y del **estado en RAM**. Si tu parte se retrasa, el resto del equipo se bloquea, así que tu primera entrega (Bloque 1) es el **contrato** que los demás usarán: carpetas, entidades e interfaces.

| Responsabilidad | Entregable |
|---|---|
| Estructura física de capas | `lib/data/`, `lib/domain/`, `lib/presentation/` (+ `lib/core/`) |
| Entidades inmutables con `assert` | `Producto`, `ItemCarrito`, `EstadoEntrega` |
| Getters/setters computados | `agotado`, `subtotal`, `total`, `totalItems`, filtro de categoría |
| Persistencia temporal en RAM | `CatalogoController extends ChangeNotifier` |
| Repositorio de catálogo (implementación) | `CatalogoRepositoryImpl` |
| Higiene del repo | `.gitignore`, repo privado, docente como colaborador, README |

---

## 2. Arquitectura que debes imponer

```
lib/
├── main.dart                          # Rol 1 (composición/inyección manual)
├── core/
│   ├── di/injection.dart              # Rol 1
│   ├── theme/app_theme.dart           # Rol 2 (tema oscuro Material 3)
│   └── utils/validators.dart          # Rol 3
├── domain/                            # Dart puro: SIN imports de flutter/material.dart
│   ├── entities/
│   │   ├── producto.dart              # Rol 1
│   │   ├── item_carrito.dart          # Rol 1
│   │   └── estado_entrega.dart        # Rol 1 (contrato) 
│   ├── repositories/
│   │   ├── catalogo_repository.dart   # Rol 1 (abstract)
│   │   └── entrega_repository.dart    # Rol 1 (abstract)
│   └── usecases/
│       ├── obtener_catalogo.dart      # Rol 1
│       ├── confirmar_compra.dart      # Rol 1
│       └── seguir_entrega.dart        # Rol 1
├── data/
│   ├── datasources/
│   │   ├── catalogo_remote_datasource.dart   # Rol 4 (Future 1 s)
│   │   └── entrega_gps_datasource.dart       # Rol 4 (Stream 3 s)
│   ├── models/producto_model.dart            # Rol 1
│   └── repositories/
│       ├── catalogo_repository_impl.dart     # Rol 1
│       └── entrega_repository_impl.dart      # Rol 4
└── presentation/
    ├── controllers/catalogo_controller.dart  # Rol 1 (todos integran)
    ├── views/
    │   ├── catalogo_view.dart                # Rol 2
    │   ├── checkout_view.dart                # Rol 3
    │   └── seguimiento_view.dart             # Rol 4
    └── widgets/                              # cada rol, en su carpeta de vista
```

### Regla de dependencias (la defiendes en la rúbrica)

```
presentation  ──►  domain  ◄──  data
(widgets, controller)  (entidades, contratos, casos de uso)  (datasources, models, repos impl)
```

- `domain` **no importa** nada de `data` ni `presentation` (ni `flutter`).
- `data` implementa las interfaces de `domain`.
- `presentation` solo habla con `domain` (casos de uso / entidades). **Ningún widget** llama a un datasource ni calcula reglas de negocio.

> Verificación rápida: `grep -rn "package:flutter" lib/domain` debe devolver **cero** resultados.

---

## 3. Plan de trabajo en UN día

| Bloque | Duración | Tu trabajo |
|---|---|---|
| **B1 – Esqueleto** | 0:00 – 1:00 | Crear proyecto, carpetas, `.gitignore`, entidades, interfaces, `main.dart` mínimo. **Push a `main` y avisar al equipo.** |
| **B2 – Núcleo** | 1:00 – 3:00 | `CatalogoController`, casos de uso, `CatalogoRepositoryImpl`, `ProductoModel`, inyección manual |
| **B3 – Integración** | 3:00 – 5:00 | Mutación de stock en checkout, vaciado reactivo del carrito, `reabastecer()`, apoyar merges |
| **B4 – Cierre** | 5:00 – 6:00 | Auditoría de capas, README, revisión de commits, entrega del repo |

---

## 4. Paso a paso

### B1.1 Crear proyecto

```bash
flutter create ecomarket_app
cd ecomarket_app
git init -b main
```

### B1.2 `.gitignore` (evaluado estrictamente)

Verifica que incluya, como mínimo:

```gitignore
/build/
.dart_tool/
.packages
.flutter-plugins
.flutter-plugins-dependencies
.idea/
*.iml
.vscode/
*.log
local.properties
```

Comprueba con `git status` que **nada** de `build/` queda rastreado. Si ya se subió: `git rm -r --cached build/`.

### B1.3 Entidad `Producto` (blindada)

`lib/domain/entities/producto.dart`

```dart
class Producto {
  final String id;
  final String nombre;
  final String categoria;
  final double precio;
  final int stock;
  final String? imagenUrl; // nulabilidad explícita: puede no haber imagen

  // Lista de inicialización + assert: valores negativos imposibles en desarrollo
  const Producto({
    required this.id,
    required this.nombre,
    required this.categoria,
    required this.precio,
    required this.stock,
    this.imagenUrl,
  })  : assert(precio >= 0, 'El precio no puede ser negativo'),
        assert(stock >= 0, 'El stock no puede ser negativo'),
        assert(nombre != '', 'El nombre no puede estar vacío');

  // Getters computados
  bool get agotado => stock == 0;
  bool hayStockPara(int cantidad) => cantidad > 0 && cantidad <= stock;

  // Inmutabilidad: para "mutar" se crea una copia
  Producto copyWith({int? stock, double? precio}) => Producto(
        id: id,
        nombre: nombre,
        categoria: categoria,
        precio: precio ?? this.precio,
        stock: stock ?? this.stock,
        imagenUrl: imagenUrl,
      );
}
```

> Los `assert` solo corren en modo debug. Para la defensa, prepara una demo: `Producto(..., stock: -1)` debe lanzar `AssertionError`. Además, el controller debe **validar en runtime** antes de crear copias (nunca depender solo de `assert`).

### B1.4 `ItemCarrito`

```dart
class ItemCarrito {
  final Producto producto;
  final int cantidad;
  const ItemCarrito({required this.producto, required this.cantidad})
      : assert(cantidad > 0);

  double get subtotal => producto.precio * cantidad; // getter computado
  ItemCarrito copyWith({int? cantidad}) =>
      ItemCarrito(producto: producto, cantidad: cantidad ?? this.cantidad);
}
```

### B1.5 Contrato de entrega (para el Rol 4)

```dart
// domain/entities/estado_entrega.dart
class EstadoEntrega {
  final int minutosRestantes;
  final double latitud;
  final double longitud;
  final String mensaje;
  const EstadoEntrega({
    required this.minutosRestantes,
    required this.latitud,
    required this.longitud,
    required this.mensaje,
  });
  bool get llego => minutosRestantes <= 0;
}
```

```dart
// domain/repositories/catalogo_repository.dart
abstract class CatalogoRepository {
  Future<List<Producto>> obtenerCatalogo(); // el Rol 4 lo respalda con un delay de 1 s
}

// domain/repositories/entrega_repository.dart
abstract class EntregaRepository {
  Stream<EstadoEntrega> seguirEntrega(); // el Rol 4 emite cada 3 s
}
```

### B2.1 Casos de uso (lógica fuera de los widgets)

```dart
class ObtenerCatalogo {
  final CatalogoRepository _repo;
  const ObtenerCatalogo(this._repo);
  Future<List<Producto>> call() => _repo.obtenerCatalogo();
}

class SeguirEntrega {
  final EntregaRepository _repo;
  const SeguirEntrega(this._repo);
  Stream<EstadoEntrega> call() => _repo.seguirEntrega();
}
```

`ConfirmarCompra` contiene la **regla de negocio** pura: recibe catálogo + carrito y devuelve el catálogo con stock descontado, o un fallo si hay stock insuficiente (sin tocar Flutter).

```dart
class ResultadoCompra {
  final bool exito;
  final String? error; // null si todo salió bien
  final List<Producto> catalogoActualizado;
  const ResultadoCompra.ok(this.catalogoActualizado) : exito = true, error = null;
  const ResultadoCompra.fallo(this.error, this.catalogoActualizado) : exito = false;
}

class ConfirmarCompra {
  const ConfirmarCompra();
  ResultadoCompra call(List<Producto> catalogo, List<ItemCarrito> carrito) {
    // 1) Validar TODO antes de mutar nada (atomicidad)
    for (final item in carrito) {
      final real = catalogo.firstWhere((p) => p.id == item.producto.id);
      if (!real.hayStockPara(item.cantidad)) {
        return ResultadoCompra.fallo(
            'Stock insuficiente de "${real.nombre}" (disponible: ${real.stock})', catalogo);
      }
    }
    // 2) Aplicar descuento
    final nuevo = catalogo.map((p) {
      final pedido = carrito.where((i) => i.producto.id == p.id);
      if (pedido.isEmpty) return p;
      return p.copyWith(stock: p.stock - pedido.first.cantidad);
    }).toList();
    return ResultadoCompra.ok(nuevo);
  }
}
```

### B2.2 `CatalogoController` (corazón del estado en RAM)

`lib/presentation/controllers/catalogo_controller.dart`

```dart
import 'package:flutter/foundation.dart';

class CatalogoController extends ChangeNotifier {
  final ObtenerCatalogo _obtenerCatalogo;
  final ConfirmarCompra _confirmarCompra;
  CatalogoController(this._obtenerCatalogo, this._confirmarCompra);

  List<Producto> _productos = [];
  final List<ItemCarrito> _carrito = [];
  String? _categoriaActiva; // null = todas

  // ---- Lectura (listas inmodificables hacia la UI) ----
  List<Producto> get productos => List.unmodifiable(_productos);
  List<ItemCarrito> get carrito => List.unmodifiable(_carrito);
  List<String> get categorias => _productos.map((p) => p.categoria).toSet().toList()..sort();

  // ---- Getter/Setter computado ----
  String? get categoriaActiva => _categoriaActiva;
  set categoriaActiva(String? valor) {
    _categoriaActiva = valor;
    notifyListeners();
  }

  List<Producto> get productosVisibles => _categoriaActiva == null
      ? productos
      : _productos.where((p) => p.categoria == _categoriaActiva).toList();

  double get total => _carrito.fold(0.0, (suma, i) => suma + i.subtotal);
  int get totalItems => _carrito.fold(0, (suma, i) => suma + i.cantidad);

  // ---- Carga (la consume el FutureBuilder del Rol 4) ----
  Future<void> cargarCatalogo() async {
    _productos = await _obtenerCatalogo();
    notifyListeners();
  }

  // ---- Carrito ----
  /// Devuelve null si todo bien; un mensaje si hay problema (la UI muestra SnackBar).
  String? agregarAlCarrito(Producto producto) {
    final idx = _carrito.indexWhere((i) => i.producto.id == producto.id);
    final enCarrito = idx == -1 ? 0 : _carrito[idx].cantidad;
    if (!producto.hayStockPara(enCarrito + 1)) {
      return 'Sin stock suficiente de "${producto.nombre}"';
    }
    if (idx == -1) {
      _carrito.add(ItemCarrito(producto: producto, cantidad: 1));
    } else {
      _carrito[idx] = _carrito[idx].copyWith(cantidad: enCarrito + 1);
    }
    notifyListeners();
    return null;
  }

  void quitarDelCarrito(String productoId) {
    _carrito.removeWhere((i) => i.producto.id == productoId);
    notifyListeners();
  }

  // ---- Pago: resta stock y vacía el carrito reactivamente ----
  /// Devuelve null si éxito, o el mensaje de error (para SnackBar).
  String? confirmarPago() {
    final r = _confirmarCompra(_productos, _carrito);
    if (!r.exito) return r.error;
    _productos = r.catalogoActualizado;
    _carrito.clear();
    notifyListeners(); // UN solo notify = refresco atómico
    return null;
  }

  // ---- FAB: reabastecer ----
  void reabastecer({int unidades = 10}) {
    _productos = _productos.map((p) => p.copyWith(stock: p.stock + unidades)).toList();
    notifyListeners(); // UN solo notify: pantalla se refresca al instante
  }
}
```

> **Importante:** un único `notifyListeners()` por operación. Si notificas dentro de un ciclo, la pantalla parpadea y la prueba de “refresco atómico” se ve mal.

### B2.3 Inyección manual y `main.dart`

```dart
// core/di/injection.dart
CatalogoController crearCatalogoController(CatalogoRepository repo) =>
    CatalogoController(ObtenerCatalogo(repo), const ConfirmarCompra());
```

```dart
// main.dart (esqueleto; el Rol 2 reemplaza el tema)
void main() {
  final catalogoRepo = CatalogoRepositoryImpl(CatalogoRemoteDataSource());
  final entregaRepo = EntregaRepositoryImpl(EntregaGpsDataSource());
  runApp(EcoMarketApp(
    controller: crearCatalogoController(catalogoRepo),
    seguirEntrega: SeguirEntrega(entregaRepo),
  ));
}

class EcoMarketApp extends StatelessWidget {
  final CatalogoController controller;
  final SeguirEntrega seguirEntrega;
  const EcoMarketApp({super.key, required this.controller, required this.seguirEntrega});

  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'EcoMarket',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.dark,
        darkTheme: AppTheme.dark,
        themeMode: ThemeMode.dark, // diseño oscuro forzado
        home: CatalogoView(controller: controller, seguirEntrega: seguirEntrega),
      );
}
```

### B2.4 Datos semilla (en `ProductoModel`/datasource)

Mínimo **8 productos**, 3–4 categorías (p. ej. Hogar, Higiene, Alimentos, Accesorios), **al menos uno con `stock: 1`** y otro con `stock: 0` para la prueba de estrés, y al menos uno con `imagenUrl: null` para demostrar `errorBuilder`.

---

## 5. Convención de commits (la rúbrica lee el historial)

Como todo ocurre en un día, la evidencia es el **historial por bloques**. Haz commits pequeños y frecuentes con prefijo de rol:

```
feat(rol1): estructura de carpetas data/domain/presentation
chore(rol1): agrega .gitignore y excluye build/
feat(rol1): entidad Producto con assert y getters computados
feat(rol1): CatalogoController con confirmarPago y reabastecer
docs(rol1): README con diagrama de capas
```

Tus archivos son **solo** los marcados “Rol 1”. Si necesitas tocar un archivo de otro rol, pídeselo o hazlo en un commit separado que lo explique.

---

## 6. Checklist de cierre (B4)

- [ ] `git status` limpio y `build/` **no** está en el repo
- [ ] `grep -rn "package:flutter" lib/domain` → sin resultados
- [ ] Ningún widget importa `data/` (`grep -rn "data/" lib/presentation` → sin resultados)
- [ ] `Producto(stock: -1)` lanza `AssertionError` en debug
- [ ] `confirmarPago()` con stock insuficiente **no modifica nada** (atomicidad)
- [ ] Un solo `notifyListeners()` por operación
- [ ] Docente agregado como colaborador del repo privado
- [ ] `flutter analyze` sin errores
- [ ] README con: integrantes/roles, diagrama de capas, cómo correr, decisiones

## 7. Rúbrica que te evalúa (Arquitectura de Capas)

| Nivel | Condición |
|---|---|
| **10** | Capas rigurosas; lógica y píxeles completamente aislados |
| 8 | Hay carpetas pero hay fugas de lógica en widgets |
| 5 | Todo mezclado en un archivo de UI |

**Preguntas probables en la defensa:** ¿por qué `domain` no importa Flutter? · ¿por qué el repositorio es una clase abstracta? · ¿qué pasa si cambias la fuente de datos a una API real? (solo cambias `data/`) · ¿por qué `Producto` es inmutable y cómo se descuenta stock?
