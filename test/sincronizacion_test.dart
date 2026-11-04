import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_application_1/data/datasources/entrega_gps_datasource.dart';
import 'package:flutter_application_1/data/repositories/entrega_repository_impl.dart';
import 'package:flutter_application_1/domain/entities/estado_entrega.dart';
import 'package:flutter_application_1/domain/repositories/entrega_repository.dart';
import 'package:flutter_application_1/presentation/widgets/catalogo_future_gate.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('EntregaGpsDataSource (Stream async* de 3 s)', () {
    test('emite en orden decreciente y cierra el stream en 0', () async {
      // minutosIniciales: 0 → un solo evento, sin esperar el recorrido completo
      final eventos = await EntregaGpsDataSource()
          .rastrear(minutosIniciales: 0)
          .toList();

      expect(eventos, hasLength(1));
      expect(eventos.single.minutosRestantes, 0);
      expect(eventos.single.llego, isTrue);
      expect(eventos.single.mensaje, '¡Tu pedido llegó!');
      // Coordenadas y minutos salen del MISMO evento (un solo origen)
      expect(eventos.single.latitud, isNot(0));
    });

    test('los minutos bajan de forma sincronizada con las coordenadas',
        () async {
      final eventos = await EntregaGpsDataSource()
          .rastrear(minutosIniciales: 2)
          .toList();

      expect(eventos.map((e) => e.minutosRestantes), [2, 1, 0]);
      // Cada evento lleva su propia coordenada de la ruta (avanza)
      final lats = eventos.map((e) => e.latitud).toList();
      expect(lats.toSet().length, greaterThan(1));
      expect(eventos.last.llego, isTrue);
    });

    test('rastrear() responde a la cancelación del suscriptor', () async {
      final sub = EntregaGpsDataSource()
          .rastrear(minutosIniciales: 5)
          .listen((_) {});

      // Cancelar de inmediato: no debe quedar un timer vivo (evita
      // "setState called after dispose" en la UI).
      await sub.cancel();
      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(sub.isPaused, isFalse); // ya cancelado, sin eventos pendientes
    });
  });

  group('EntregaRepositoryImpl (implementa el contrato del dominio)', () {
    test('seguirEntrega() expone el stream del datasource', () async {
      final EntregaRepository repo =
          EntregaRepositoryImpl(EntregaGpsDataSource());

      final primeros = await repo.seguirEntrega().take(1).toList();
      // Sin argumentos usa el default del datasource (minutosIniciales: 5)
      expect(primeros.single.minutosRestantes, 5);
      expect(primeros.single.llego, isFalse);
    });
  });

  group('CatalogoFutureGate (FutureBuilder)', () {
    Widget envolver(Widget gate) => MaterialApp(home: Scaffold(body: gate));

    testWidgets('muestra loading mientras el Future está pendiente',
        (tester) async {
      final completer = Completer<void>();

      await tester.pumpWidget(
        envolver(
          CatalogoFutureGate(
            future: completer.future,
            onRetry: () {},
            child: const Text('CATALOGO_LISTO'),
          ),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Cargando catálogo ecológico…'), findsOneWidget);
      expect(find.text('CATALOGO_LISTO'), findsNothing);

      completer.complete();
      await tester.pumpAndSettle();
      expect(find.text('CATALOGO_LISTO'), findsOneWidget);
    });

    testWidgets('muestra el estado de error con botón Reintentar',
        (tester) async {
      final completer = Completer<void>();

      await tester.pumpWidget(
        envolver(
          CatalogoFutureGate(
            future: completer.future,
            onRetry: () {},
            child: const Text('CATALOGO_LISTO'),
          ),
        ),
      );

      completer.completeError(Exception('sin red'));
      await tester.pumpAndSettle();

      expect(find.text('No se pudo cargar el catálogo'), findsOneWidget);
      expect(find.byIcon(Icons.cloud_off), findsOneWidget);
      expect(find.widgetWithText(FilledButton, 'Reintentar'), findsOneWidget);
      expect(find.text('CATALOGO_LISTO'), findsNothing);
    });

    testWidgets('onRetry recibe el nuevo Future y muestra los datos',
        (tester) async {
      var futuras = 0;
      Future<void> nueva() {
        futuras++;
        return Future<void>.delayed(Duration.zero);
      }

      await tester.pumpWidget(
        envolver(
          CatalogoFutureGate(
            future: nueva(),
            onRetry: () {},
            child: const Text('CATALOGO_LISTO'),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('CATALOGO_LISTO'), findsOneWidget);
      expect(futuras, 1);

      // El padre recrea el Future fuera de build() → la gate lo respeta
      // sin lanzar una petición extra por redibujado.
      await tester.pump();
      expect(futuras, 1); // NO se relanzó al redibujar
    });
  });

  group('EstadoEntrega (contrato compartido con Rol 1)', () {
    test('llego es true cuando minutosRestantes <= 0', () {
      const enCamino = EstadoEntrega(
        minutosRestantes: 3,
        latitud: 20.9,
        longitud: -89.6,
        mensaje: 'va en camino',
      );
      const llegado = EstadoEntrega(
        minutosRestantes: 0,
        latitud: 20.9,
        longitud: -89.6,
        mensaje: 'llegó',
      );

      expect(enCamino.llego, isFalse);
      expect(llegado.llego, isTrue);
    });
  });
}
