import 'package:flutter/material.dart';
import 'package:flutter_application_1/domain/entities/producto.dart';
import 'package:flutter_application_1/domain/repositories/catalogo_repository.dart';
import 'package:flutter_application_1/domain/repositories/entrega_repository.dart';
import 'package:flutter_application_1/domain/usecases/confirmar_compra.dart';
import 'package:flutter_application_1/domain/usecases/obtener_catalogo.dart';
import 'package:flutter_application_1/domain/usecases/seguir_entrega.dart';
import 'package:flutter_application_1/main.dart';
import 'package:flutter_application_1/presentation/controllers/catalogo_controller.dart';
import 'package:flutter_application_1/presentation/widgets/producto_card.dart';
import 'package:flutter_test/flutter_test.dart';

/// Repo falso inmediato (sin delays reales) con nombres largos y muchas
/// categorías para estresar el layout.
class _RepoFalso implements CatalogoRepository {
  @override
  Future<List<Producto>> obtenerCatalogo() async => const [
        Producto(id: '1', nombre: 'Botella reutilizable de acero inoxidable con tapa de bambú', categoria: 'Hogar', precio: 249, stock: 12),
        Producto(id: '2', nombre: 'Cepillo de bambú (pack 4)', categoria: 'Higiene', precio: 99, stock: 20),
        Producto(id: '3', nombre: 'Bolsas de tela orgánica', categoria: 'Accesorios', precio: 129, stock: 1),
        Producto(id: '4', nombre: 'Jabón artesanal de avena', categoria: 'Cuidado personal', precio: 59, stock: 0),
        Producto(id: '5', nombre: 'Granola orgánica 500 g', categoria: 'Alimentos', precio: 89, stock: 15),
        Producto(id: '6', nombre: 'Popotes de vidrio (set)', categoria: 'Cocina sustentable', precio: 79, stock: 8),
        Producto(id: '7', nombre: 'Café de altura molido', categoria: 'Bebidas', precio: 159, stock: 6),
        Producto(id: '8', nombre: 'Lonchera de acero inoxidable', categoria: 'Oficina verde', precio: 319, stock: 4),
        Producto(id: '9', nombre: 'Composta doméstica', categoria: 'Jardín', precio: 999.99, stock: 3),
      ];
}

/// El test de catálogo nunca abre el seguimiento: el repo de entregas
/// no debe llamarse.
class _EntregaFalsa implements EntregaRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('No se usa en este test');
}

CatalogoController _controller() =>
    CatalogoController(ObtenerCatalogo(_RepoFalso()), const ConfirmarCompra());

Widget construirAppDePrueba({double escalaTexto = 1.0}) {
  final app = EcoMarketApp(
    controller: _controller(),
    seguirEntrega: SeguirEntrega(_EntregaFalsa()),
    mostrarPresentacion: false, // este test cubre el catálogo, no el splash
  );
  if (escalaTexto == 1.0) return app;
  return Builder(
    builder: (context) => MediaQuery(
      data: MediaQuery.of(context)
          .copyWith(textScaler: TextScaler.linear(escalaTexto)),
      child: app,
    ),
  );
}

void main() {
  const tamanos = <String, Size>{
    'telefono pequeño': Size(320, 568),
    'telefono estandar': Size(411, 891),
    'telefono horizontal': Size(891, 411),
    'tablet': Size(800, 1280),
    'escritorio': Size(1366, 768),
  };

  Future<void> montar(WidgetTester tester, Size size,
      {double escalaTexto = 1.0}) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(construirAppDePrueba(escalaTexto: escalaTexto));
    await tester.pump(const Duration(seconds: 2)); // termina el Future
  }

  void verificarOscuro(WidgetTester tester) {
    final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
    expect(app.themeMode, ThemeMode.dark);
    expect(
      Theme.of(tester.element(find.byType(Scaffold).first)).brightness,
      Brightness.dark,
    );
  }

  for (final e in tamanos.entries) {
    testWidgets('Catálogo sin overflow y en modo oscuro — ${e.key}',
        (tester) async {
      await montar(tester, e.value);

      expect(tester.takeException(), isNull); // sin RenderFlex overflow
      // skipOffstage: false → en el teléfono pequeño los chips ocupan casi
      // toda la pantalla y las tarjetas se construyen justo debajo.
      expect(find.byType(ProductoCard, skipOffstage: false), findsWidgets);
      verificarOscuro(tester);

      // Hacer scroll hasta el final tampoco debe desbordar
      await tester.drag(find.byType(CustomScrollView), const Offset(0, -3000));
      await tester.pump();
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('Texto del sistema al 160 % sin overflow (accesibilidad)',
      (tester) async {
    await montar(tester, const Size(360, 640), escalaTexto: 1.6);
    expect(tester.takeException(), isNull);
    verificarOscuro(tester);
  });

  testWidgets('Agregar al carrito actualiza el badge y Rellenar Stock avisa',
      (tester) async {
    await montar(tester, const Size(411, 891));

    expect(find.byType(Badge), findsOneWidget);
    expect(find.text('1'), findsNothing);

    await tester.tap(find.text('Agregar').first);
    await tester.pump();
    expect(
      find.descendant(of: find.byType(Badge), matching: find.text('1')),
      findsOneWidget,
    );

    await tester.tap(find.text('Rellenar Stock'));
    await tester.pump();
    expect(find.text('Stock rellenado'), findsOneWidget);
  });

  testWidgets('Filtrar por categoría con los chips del Wrap', (tester) async {
    await montar(tester, const Size(1366, 768));

    expect(find.byType(ProductoCard), findsNWidgets(9));
    await tester.tap(find.widgetWithText(ChoiceChip, 'Jardín'));
    await tester.pump();
    expect(find.byType(ProductoCard), findsOneWidget);
    expect(find.textContaining('Composta'), findsOneWidget);
  });
}
