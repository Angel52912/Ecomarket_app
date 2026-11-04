# Rol 2 — UI Responsiva (Frontend)

Capa visual del catálogo de EcoMarket: **oscura**, **responsive**, sin lógica de negocio.

## Archivos del Rol 2

| Archivo | Descripción |
|---|---|
| `lib/core/theme/app_theme.dart` | Tema oscuro Material 3 |
| `lib/presentation/views/catalogo_view.dart` | `CustomScrollView` + `SliverAppBar(pinned)` + `SliverGrid` (0.65) + FAB + badge del carrito |
| `lib/presentation/widgets/categorias_wrap.dart` | Filtros con `Wrap` + `ChoiceChip` |
| `lib/presentation/widgets/producto_card.dart` | Tarjeta con `loadingBuilder` / `errorBuilder` |
| `test/responsive_dark_test.dart` | Anti-overflow en 5 tamaños × 2 escalas de texto + modo oscuro |

## Placeholders (NO son del Rol 2, reemplazar por la versión real)

Solo existen para que la UI compile. Mantienen la interfaz pública que consume la vista.

| Archivo | Dueño |
|---|---|
| `lib/domain/entities/producto.dart` | Rol 1 |
| `lib/presentation/controllers/catalogo_controller.dart` | Rol 1 |
| `lib/domain/usecases/seguir_entrega.dart` | Rol 4 |
| `lib/presentation/widgets/catalogo_future_gate.dart` | Rol 4 |
| `lib/presentation/views/checkout_view.dart` | Checkout |
| `lib/main.dart` (inyección de dependencias) | Rol 4 |

Al reemplazar `CatalogoController`, mantén su constructor compatible con el test
(`productosIniciales`) o ajusta `construirAppDePrueba()` para inyectar repos falsos.

## Uso

```bash
flutter test test/responsive_dark_test.dart
flutter run -d chrome        # redimensiona la ventana para ver 2 → 5 columnas
```

> Si el paquete no se llama `ecomarket`, cambia los imports `package:ecomarket/...` del test.

## Checklist manual

- [ ] Teléfono vertical (≈360×640): 2 columnas, sin franjas de overflow
- [ ] Teléfono horizontal: más columnas, el AppBar colapsa bien y el FAB no tapa la última fila
- [ ] Tablet / ventana ancha: 3–5 columnas, tarjetas con proporción 0.65
- [ ] 8+ categorías saltan de línea sin desborde
- [ ] Texto del sistema al 150–200 %: sin overflow
- [ ] Tema oscuro en todas las pantallas; cero fondos blancos
- [ ] Cambiar el tema del sistema a claro no cambia la app
- [ ] URL de imagen rota → icono; `imagenUrl == null` → placeholder
- [ ] Un solo scroll en el catálogo
- [ ] Hot restart sin excepciones

## Capturas

_Agregar 3 capturas (teléfono, horizontal, escritorio) en `docs/capturas/`._

## Commits sugeridos

```
feat(rol2): scaffold base y Wrap de categorias
feat(rol2): tema oscuro Material 3 en AppTheme
feat(rol2): CustomScrollView con SliverAppBar pinned
feat(rol2): SliverGrid responsivo childAspectRatio 0.65
feat(rol2): ProductoCard con loadingBuilder y errorBuilder
test(rol2): pruebas de overflow y modo oscuro en 5 tamaños
```
