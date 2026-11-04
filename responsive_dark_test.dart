import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// ⚠️ Ajusta "ecomarket" al nombre real del paquete (campo `name:` del pubspec.yaml).
import 'package:ecomarket/core/theme/app_theme.dart';
import 'package:ecomarket/domain/entities/producto.dart';
import 'package:ecomarket/domain/usecases/seguir_entrega.dart';
import 'package:ecomarket/presentation/controllers/catalogo_controller.dart';
import 'package:ecomarket/presentation/views/catalogo_view.dart';

/// Datos locales de prueba (sin red ni delays reales).
/// Incluye: nombre muy largo, producto agotado, imagen rota e imagen nula.
const _productosPrueba = <Producto>[
  Producto(
    id: '1',
    nombre: 'Botella reutilizable de acero inoxidable con aislamiento térmico doble pared',
    precio: 24.99,
    stock: 10,
    categoria: 'Hogar',
    imagenUrl: 'https://url-rota.invalid/botella.png', // dispara errorBuilder
  ),
  Producto(id: '2', nombre: 'Bolsa de tela', precio: 5.5, stock: 0, categoria: 'Accesorios'),
  Producto(id: '3', nombre: 'Cepillo de bambú', precio: 3.25, stock: 40, categoria: 'Higiene'),
  Producto(id: '4', nombre: 'Jabón artesanal', precio: 6.0, stock: 12, categoria: 'Higiene'),
  Producto(id: '5', nombre: 'Popote de acero', precio: 2.0, stock: 99, categoria: 'Cocina'),
  Producto(id: '6', nombre: 'Compostero doméstico', precio: 59.9, stock: 3, categoria: 'Jardín'),
  Producto(id: '7', nombre: 'Envoltorio de cera de abeja', precio: 9.9, stock: 7, categoria: 'Cocina'),
  Producto(id: '8', nombre: 'Panel solar portátil', precio: 89.0, stock: 2, categoria: 'Energía'),
  Producto(id: '9', nombre: 'Termo de bambú', precio: 19.0, stock: 15, categoria: 'Hogar'),
  Producto(id: '10', nombre: 'Detergente biodegradable', precio: 8.4, stock: 22, categoria: 'Limpieza'),
];

Widget construirAppDePrueba({double escalaTexto = 1.0}) => MaterialApp(
      theme: AppTheme.dark,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.dark,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context)
            .copyWith(textScaler: TextScaler.linear(escalaTexto)),
        child: child!,
      ),
      home: CatalogoView(
        controller: CatalogoController(productosIniciales: _productosPrueba),
        seguirEntrega: const SeguirEntrega(),
      ),
    );

void main() {
  const tamanos = <String, Size>{
    'telefono pequeño': Size(320, 568),
    'telefono estandar': Size(411, 891),
    'telefono horizontal': Size(891, 411),
    'tablet': Size(800, 1280),
    'escritorio': Size(1366, 768),
  };

  for (final escala in const [1.0, 1.6]) {
    for (final e in tamanos.entries) {
      testWidgets(
        'Catálogo sin overflow y en modo oscuro — ${e.key} (texto x$escala)',
        (tester) async {
          tester.view.physicalSize = e.value;
          tester.view.devicePixelRatio = 1.0;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);

          await tester.pumpWidget(construirAppDePrueba(escalaTexto: escala));
          await tester.pump(const Duration(seconds: 2)); // termina el Future

          expect(tester.takeException(), isNull); // sin RenderFlex overflow

          final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
          expect(app.themeMode, ThemeMode.dark);
          expect(
            Theme.of(tester.element(find.byType(Scaffold).first)).brightness,
            Brightness.dark,
          );
        },
      );
    }
  }

  testWidgets('Un solo scroll vertical en el catálogo', (tester) async {
    tester.view.physicalSize = const Size(411, 891);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(construirAppDePrueba());
    await tester.pump(const Duration(seconds: 2));

    expect(find.byType(CustomScrollView), findsOneWidget);
    expect(find.byType(GridView), findsNothing);
    expect(find.byType(ListView), findsNothing);
  });
}
