import '../../domain/repositories/catalogo_repository.dart';
import '../../domain/usecases/confirmar_compra.dart';
import '../../domain/usecases/obtener_catalogo.dart';
import '../../presentation/controllers/catalogo_controller.dart';

/// Inyección manual (sin framework): `main` decide qué implementación
/// concreta recibe cada contrato. Cambiar la fuente de datos solo exige
/// tocar esta línea, no el controller ni los widgets.
CatalogoController crearCatalogoController(CatalogoRepository repo) =>
    CatalogoController(ObtenerCatalogo(repo), const ConfirmarCompra());
