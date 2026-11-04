// NOTA (Rol 1): stub mínimo para desbloquear `flutter analyze` y la demo.
// El Rol 4 debe reemplazar esta clase por su implementación real con
// `Future.delayed(Duration(seconds: 1))` sobre una fuente remota.
import '../models/producto_model.dart';

class CatalogoRemoteDataSource {
  /// Simula una llamada de red con 1 s de latencia (Rol 4).
  Future<List<ProductoModel>> obtenerCatalogo() async {
    await Future<void>.delayed(const Duration(seconds: 1));
    return ProductoModel.semilla;
  }
}
