import 'package:dio/dio.dart';
import '../../core/constants/api_endpoints.dart';
import '../models/analysis_model.dart';
import 'api_client.dart';

class AnalysisService {
  final ApiClient _apiClient = ApiClient();

  Future<Map<String, double>> getExpensesByCategory({int? mes, int? anio}) async {
    try {
      final queryParams = <String, dynamic>{};
      if (mes != null) queryParams['mes'] = mes;
      if (anio != null) queryParams['año'] = anio;

      final response = await _apiClient.dio.get(
        ApiEndpoints.expensesSummary,
        queryParameters: queryParams,
      );

      final Map<String, dynamic> data = response.data;
      final result = <String, double>{};
      data.forEach((key, value) {
        result[key] = (value as num).toDouble();
      });
      return result;
    } on DioException catch (e) {
      final message = e.response?.data['detail'] ?? 'Error al obtener resumen de gastos por categoría';
      throw Exception(message);
    }
  }

  Future<SimulationResult> simulatePurchase(double amount) async {
    try {
      final response = await _apiClient.dio.post(
        ApiEndpoints.simulate,
        data: {'monto_compra': amount},
      );
      return SimulationResult.fromJson(response.data);
    } on DioException catch (e) {
      final message = e.response?.data['detail'] ?? 'Error al realizar la simulación de compra';
      throw Exception(message);
    }
  }

  Future<SavingsProjectionResult> getSavingsProjection({
    required String categoria,
    required double gastoActualMensual,
    required double gastoObjetivoMensual,
  }) async {
    try {
      final response = await _apiClient.dio.post(
        ApiEndpoints.savingsProjection,
        data: {
          'categoria': categoria,
          'gasto_actual_mensual': gastoActualMensual,
          'gasto_objetivo_mensual': gastoObjetivoMensual,
        },
      );
      return SavingsProjectionResult.fromJson(response.data);
    } on DioException catch (e) {
      final message = e.response?.data['detail'] ?? 'Error al calcular la proyección de ahorro';
      throw Exception(message);
    }
  }

  /// Resumen general del mes + comparativa al mes anterior (pantalla 1A).
  Future<AnalysisOverview> getOverview({int? mes, int? anio}) async {
    try {
      final queryParams = <String, dynamic>{};
      if (mes != null) queryParams['mes'] = mes;
      if (anio != null) queryParams['año'] = anio;

      final response = await _apiClient.dio.get(
        ApiEndpoints.analysisOverview,
        queryParameters: queryParams,
      );
      return AnalysisOverview.fromJson(response.data);
    } on DioException catch (e) {
      final message = e.response?.data['detail'] ?? 'Error al obtener el resumen de análisis';
      throw Exception(message);
    }
  }

  /// Detalle de una categoría: total, comparativa, % y desglose por comercio (pantalla 1D).
  Future<CategoryDetail> getCategoryDetail({
    required String categoria,
    int? mes,
    int? anio,
  }) async {
    try {
      final queryParams = <String, dynamic>{'categoria': categoria};
      if (mes != null) queryParams['mes'] = mes;
      if (anio != null) queryParams['año'] = anio;

      final response = await _apiClient.dio.get(
        ApiEndpoints.analysisCategoryDetail,
        queryParameters: queryParams,
      );
      return CategoryDetail.fromJson(response.data);
    } on DioException catch (e) {
      final message = e.response?.data['detail'] ?? 'Error al obtener el detalle de la categoría';
      throw Exception(message);
    }
  }
}
