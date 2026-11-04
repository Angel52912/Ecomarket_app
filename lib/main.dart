import 'package:flutter/material.dart';

import 'core/di/injection.dart';
import 'core/theme/app_theme.dart';
import 'data/datasources/catalogo_remote_datasource.dart';
import 'data/datasources/entrega_gps_datasource.dart';
import 'data/repositories/catalogo_repository_impl.dart';
import 'data/repositories/entrega_repository_impl.dart';
import 'domain/usecases/seguir_entrega.dart';
import 'presentation/controllers/catalogo_controller.dart';
import 'presentation/views/catalogo_view.dart';

void main() {
  // Composición / inyección manual (Rol 1): aquí se decide qué implementación
  // concreta satisface cada contrato del dominio.
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

  const EcoMarketApp({
    super.key,
    required this.controller,
    required this.seguirEntrega,
  });

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
