import 'package:flutter/material.dart';
import 'package:flutter_application_1/core/theme/app_theme.dart';
import 'package:flutter_application_1/domain/entities/estado_entrega.dart';
import 'package:flutter_application_1/domain/entities/producto.dart';
import 'package:flutter_application_1/domain/repositories/catalogo_repository.dart';
import 'package:flutter_application_1/domain/repositories/entrega_repository.dart';
import 'package:flutter_application_1/domain/usecases/confirmar_compra.dart';
import 'package:flutter_application_1/domain/usecases/obtener_catalogo.dart';
import 'package:flutter_application_1/domain/usecases/seguir_entrega.dart';
import 'package:flutter_application_1/presentation/controllers/catalogo_controller.dart';
import 'package:flutter_application_1/presentation/views/checkout_view.dart';
import 'package:flutter_application_1/presentation/views/seguimiento_view.dart';
import 'package:flutter_test/flutter_test.dart';

/// Repo mutable: permite simular que otro pedido redujo el stock después
/// de agregar al carrito (prueba de estrés).
class _RepoFalso implements CatalogoRepository {
  List<Producto> catalogo = const [
    Producto(id: 'a', nombre: 'Jabón de avena', categoria: 'Higiene', precio: 59, stock: 5),
    Producto(id: 'b', nombre: 'Bolsas de tela', categoria: 'Accesorios', precio: 129, stock: 1),
  ];

  @override
  Future<List<Producto>> obtenerCatalogo() async => catalogo;
}

class _EntregaFalsa implements EntregaRepository {
  @override
  Stream<EstadoEntrega> seguirEntrega() => Stream.value(const EstadoEntrega(
        minutosRestantes: 0,
        latitud: 21.0,
        longitud: -89.6,
        mensaje: '¡Tu pedido llegó!',
      ));
}

void main() {
  late _RepoFalso repo;
  late CatalogoController c;

  setUp(() async {
    repo = _RepoFalso();
    c = CatalogoController(ObtenerCatalogo(repo), const ConfirmarCompra());
    await c.cargarCatalogo();
  });

  Future<void> montar(WidgetTester tester, {Size size = const Size(411, 891)}) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.dark,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.dark,
      home: CheckoutView(
        controller: c,
        seguirEntrega: SeguirEntrega(_EntregaFalsa()),
      ),
    ));
  }

  Future<void> llenarValido(WidgetTester tester) async {
    final campos = find.byType(TextFormField);
    await tester.enterText(campos.at(0), 'José Cámara');
    await tester.enterText(campos.at(1), 'jose@dominio.com');
    await tester.enterText(campos.at(2), '9991234567');
    await tester.enterText(campos.at(3), 'Calle 60 #123, Centro');
    await tester.enterText(campos.at(4), '97000');
    await tester.pump();
  }

  Future<void> tocarPagar(WidgetTester tester) async {
    final boton = find.textContaining('Pagar');
    await tester.ensureVisible(boton);
    await tester.tap(boton);
    await tester.pump();
  }

  testWidgets('carrito vacío muestra mensaje y no muestra formulario',
      (tester) async {
    await montar(tester);
    expect(find.text('Tu carrito está vacío'), findsOneWidget);
    expect(find.byType(Form), findsNothing);
  });

  testWidgets('enviar vacío marca TODOS los campos en rojo a la vez',
      (tester) async {
    c.agregarAlCarrito(c.productos.first);
    await montar(tester);

    await tocarPagar(tester);

    expect(find.text('El nombre es obligatorio'), findsOneWidget);
    expect(find.text('El correo es obligatorio'), findsOneWidget);
    expect(find.text('El teléfono es obligatorio'), findsOneWidget);
    expect(find.text('La dirección es obligatoria'), findsOneWidget);
    expect(find.text('El código postal es obligatorio'), findsOneWidget);
    // Datos inválidos nunca llegan al controller
    expect(c.carrito, hasLength(1));
    expect(c.productos.first.stock, 5);
  });

  testWidgets('el teléfono filtra letras y limita a 10 dígitos',
      (tester) async {
    c.agregarAlCarrito(c.productos.first);
    await montar(tester);

    final tel = find.byType(TextFormField).at(2);
    await tester.enterText(tel, '99ab912345678901');
    await tester.pump();
    final editable = tester.widget<EditableText>(
      find.descendant(of: tel, matching: find.byType(EditableText)),
    );
    expect(editable.controller.text, '9991234567');
  });

  testWidgets('datos válidos: descuenta stock, vacía carrito y va a Seguimiento',
      (tester) async {
    c.agregarAlCarrito(c.productos.first);
    c.agregarAlCarrito(c.productos.first);
    await montar(tester);

    expect(find.text('Pagar \$118.00'), findsOneWidget);
    await llenarValido(tester);
    await tocarPagar(tester);
    await tester.pumpAndSettle();

    expect(c.carrito, isEmpty);
    expect(c.productos.first.stock, 3);
    expect(find.byType(SeguimientoView), findsOneWidget);
  });

  testWidgets('stock insuficiente: SnackBar y NADA se descuenta',
      (tester) async {
    c.agregarAlCarrito(c.productos.last); // 'b' con stock 1
    // Otro pedido se llevó la última unidad
    repo.catalogo = const [
      Producto(id: 'a', nombre: 'Jabón de avena', categoria: 'Higiene', precio: 59, stock: 5),
      Producto(id: 'b', nombre: 'Bolsas de tela', categoria: 'Accesorios', precio: 129, stock: 0),
    ];
    await c.cargarCatalogo();
    await montar(tester);

    await llenarValido(tester);
    await tocarPagar(tester);

    expect(find.byType(SnackBar), findsOneWidget);
    expect(find.text('Rellenar Stock'), findsOneWidget);
    expect(c.carrito, hasLength(1)); // atomicidad: nada se mutó
    expect(c.productos.last.stock, 0);
    expect(find.byType(SeguimientoView), findsNothing);
  });

  testWidgets('formulario sin overflow en 320 px, horizontal y escritorio',
      (tester) async {
    c.agregarAlCarrito(c.productos.first);
    for (final size in const [Size(320, 568), Size(891, 411), Size(1366, 768)]) {
      await montar(tester, size: size);
      await tocarPagar(tester); // errores visibles = máxima altura
      expect(tester.takeException(), isNull);
      expect(
        Theme.of(tester.element(find.byType(Form))).brightness,
        Brightness.dark,
      );
    }
  });
}
