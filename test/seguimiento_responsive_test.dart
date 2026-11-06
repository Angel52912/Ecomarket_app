import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_application_1/core/theme/app_theme.dart';
import 'package:flutter_application_1/domain/entities/estado_entrega.dart';
import 'package:flutter_application_1/domain/repositories/entrega_repository.dart';
import 'package:flutter_application_1/domain/usecases/seguir_entrega.dart';
import 'package:flutter_application_1/presentation/views/seguimiento_view.dart';
import 'package:flutter_test/flutter_test.dart';

/// GPS falso controlado por el test: el StreamController lo maneja la prueba,
/// así se simulan eventos, error y cierre (`ConnectionState.done`) a demanda.
class _EntregaFalsa implements EntregaRepository {
  final StreamController<EstadoEntrega> controlador;
  int llamadas = 0; // cuenta cuántas veces se (re)suscribe la vista

  _EntregaFalsa(this.controlador);

  @override
  Stream<EstadoEntrega> seguirEntrega() {
    llamadas++;
    return controlador.stream;
  }
}

const _enCamino = EstadoEntrega(
  minutosRestantes: 5,
  latitud: 20.9754,
  longitud: -89.6170,
  mensaje: 'Tu repartidor va en camino',
);

void main() {
  const tamanos = <String, Size>{
    'telefono pequeño (320 px)': Size(320, 568),
    'telefono horizontal': Size(891, 411),
    'escritorio': Size(1366, 768),
  };

  /// Monta [SeguimientoView] a un tamaño dado con su controller a mano.
  Future<
      ({
        WidgetTester tester,
        _EntregaFalsa entrega,
        StreamController<EstadoEntrega> controlador,
      })> montar(WidgetTester tester, Size size) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final controlador = StreamController<EstadoEntrega>.broadcast();
    final entrega = _EntregaFalsa(controlador);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark,
        home: SeguimientoView(seguirEntrega: SeguirEntrega(entrega)),
      ),
    );
    return (tester: tester, entrega: entrega, controlador: controlador);
  }

  for (final e in tamanos.entries) {
    testWidgets('Seguimiento sin overflow y en modo oscuro — ${e.key}',
        (tester) async {
      final m = await montar(tester, e.value);

      // Estado de carga inicial (sin eventos aún)
      expect(find.text('Conectando con el repartidor…'), findsOneWidget);
      expect(tester.takeException(), isNull);

      m.controlador.add(_enCamino);
      await tester.pump();
      expect(find.text('Tu repartidor va en camino'), findsOneWidget);
      expect(find.text('5 min restantes'), findsOneWidget);
      expect(tester.takeException(), isNull); // sin RenderFlex overflow

      // Modo oscuro (restricción global)
      expect(
        Theme.of(tester.element(find.byType(Scaffold))).brightness,
        Brightness.dark,
      );

      m.controlador.close();
    });
  }

  testWidgets('Rotación NO reinicia el reloj ni re-suscribe el stream',
      (tester) async {
    final m = await montar(tester, const Size(411, 891));

    m.controlador.add(_enCamino);
    await tester.pump();
    expect(find.text('5 min restantes'), findsOneWidget);
    expect(m.entrega.llamadas, 1); // el stream se creó UNA sola vez

    // Rotar a horizontal: cambia el LayoutBuilder, pero el State persiste
    tester.view.physicalSize = const Size(891, 411);
    await tester.pump();
    expect(tester.takeException(), isNull);
    expect(m.entrega.llamadas, 1); // NO volvió a suscribirse → reloj intacto

    // El stream sigue vivo: llega el siguiente estado sin reiniciar
    m.controlador.add(
      const EstadoEntrega(
        minutosRestantes: 4,
        latitud: 20.9731,
        longitud: -89.6139,
        mensaje: 'Tu repartidor va en camino',
      ),
    );
    await tester.pump();
    expect(find.text('4 min restantes'), findsOneWidget);
    expect(m.entrega.llamadas, 1);

    m.controlador.close();
  });

  testWidgets('Stream cerrado (done) muestra el botón sin overflow en 320 px',
      (tester) async {
    final m = await montar(tester, const Size(320, 568));

    m.controlador.add(_enCamino);
    await tester.pump();
    expect(find.widgetWithText(FilledButton, 'Volver al catálogo'), findsNothing);

    m.controlador.add(
      const EstadoEntrega(
        minutosRestantes: 0,
        latitud: 20.9630,
        longitud: -89.5998,
        mensaje: '¡Tu pedido llegó!',
      ),
    );
    await tester.pump();
    expect(find.byIcon(Icons.check_circle), findsOneWidget);
    expect(find.text('Entregado'), findsOneWidget);

    m.controlador.close(); // ConnectionState.done
    await tester.pump(); // entrega el done al StreamBuilder
    await tester.pump(); // redibuja con connectionState == done
    expect(find.widgetWithText(FilledButton, 'Volver al catálogo'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Error del stream muestra el aviso de señal GPS', (tester) async {
    final m = await montar(tester, const Size(411, 891));

    m.controlador.addError(Exception('GPS caído'));
    await tester.pump();
    expect(find.text('Se perdió la señal del GPS'), findsOneWidget);
    expect(tester.takeException(), isNull);

    m.controlador.close();
  });
}
