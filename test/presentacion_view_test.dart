import 'package:flutter/material.dart';
import 'package:flutter_application_1/core/theme/app_theme.dart';
import 'package:flutter_application_1/domain/entities/producto.dart';
import 'package:flutter_application_1/domain/repositories/catalogo_repository.dart';
import 'package:flutter_application_1/domain/repositories/entrega_repository.dart';
import 'package:flutter_application_1/domain/usecases/confirmar_compra.dart';
import 'package:flutter_application_1/domain/usecases/obtener_catalogo.dart';
import 'package:flutter_application_1/domain/usecases/seguir_entrega.dart';
import 'package:flutter_application_1/main.dart';
import 'package:flutter_application_1/presentation/controllers/catalogo_controller.dart';
import 'package:flutter_application_1/presentation/views/catalogo_view.dart';
import 'package:flutter_application_1/presentation/views/presentacion_view.dart';
import 'package:flutter_test/flutter_test.dart';

/// Repo falso inmediato (sin delays) para que el catálogo cargue al instante.
class _RepoFalso implements CatalogoRepository {
  @override
  Future<List<Producto>> obtenerCatalogo() async => const [
        Producto(
          id: '1',
          nombre: 'Botella reutilizable de acero',
          categoria: 'Hogar',
          precio: 249,
          stock: 12,
        ),
      ];
}

class _EntregaFalsa implements EntregaRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('No se usa en este test');
}

CatalogoController _controller() =>
    CatalogoController(ObtenerCatalogo(_RepoFalso()), const ConfirmarCompra());

Widget _app() => EcoMarketApp(
      controller: _controller(),
      seguirEntrega: SeguirEntrega(_EntregaFalsa()),
    );

void main() {
  Future<void> montar(WidgetTester tester, Size size) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(_app());
  }

  testWidgets('Presentación muestra la marca y pasa al catálogo sola',
      (tester) async {
    await montar(tester, const Size(411, 891));

    expect(find.byType(PresentacionView), findsOneWidget);
    expect(find.text('EcoMarket'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'Comenzar'), findsOneWidget);
    expect(tester.takeException(), isNull);

    // Modo oscuro forzado (restricción global)
    expect(
      Theme.of(tester.element(find.byType(Scaffold))).brightness,
      Brightness.dark,
    );

    // El timer de initState dispara a los 2.8 s → entra al catálogo
    await tester.pump(const Duration(milliseconds: 2800));
    await tester.pumpAndSettle(); // transición de ruta + carga del catálogo

    expect(find.byType(CatalogoView), findsOneWidget);
    expect(find.byType(PresentacionView), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Botón Comenzar entra al catálogo sin esperar al timer',
      (tester) async {
    await montar(tester, const Size(411, 891));

    await tester.tap(find.widgetWithText(FilledButton, 'Comenzar'));
    await tester.pumpAndSettle();

    expect(find.byType(CatalogoView), findsOneWidget);

    // El timer cancelado en dispose no debe navegar una segunda vez
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
    expect(find.byType(CatalogoView), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Presentación sin overflow — teléfono pequeño 320 px',
      (tester) async {
    await montar(tester, const Size(320, 568));

    expect(find.byType(PresentacionView), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Presentación sin overflow — horizontal 891x411', (tester) async {
    await montar(tester, const Size(891, 411));

    expect(find.byType(PresentacionView), findsOneWidget);
    expect(tester.takeException(), isNull);

    // Seguir siendo utilizable en horizontal: el botón responde
    await tester.tap(find.widgetWithText(FilledButton, 'Comenzar'));
    await tester.pumpAndSettle();
    expect(find.byType(CatalogoView), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Rotación durante la presentación no reinicia la animación',
      (tester) async {
    await montar(tester, const Size(411, 891));
    await tester.pump(const Duration(milliseconds: 500)); // animación a medio camino

    // Rotar: initState NO se vuelve a ejecutar → el timer sigue su curso
    tester.view.physicalSize = const Size(891, 411);
    await tester.pump();
    expect(tester.takeException(), isNull);
    expect(find.byType(PresentacionView), findsOneWidget);

    // Completar el tiempo total desde el arranque (500 + 2300 = 2800)
    await tester.pump(const Duration(milliseconds: 2300));
    await tester.pumpAndSettle();
    expect(find.byType(CatalogoView), findsOneWidget);
  });

  testWidgets('AppTheme directo: presentación también respeta el modo oscuro',
      (tester) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark,
        home: PresentacionView(
          controller: _controller(),
          seguirEntrega: SeguirEntrega(_EntregaFalsa()),
        ),
      ),
    );

    expect(
      Theme.of(tester.element(find.byType(Scaffold))).brightness,
      Brightness.dark,
    );
    expect(tester.takeException(), isNull);
  });
}
