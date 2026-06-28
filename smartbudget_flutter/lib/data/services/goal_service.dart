import 'package:dio/dio.dart';
import '../../core/constants/api_endpoints.dart';
import '../models/goal_model.dart';
import 'api_client.dart';

class GoalService {
  final ApiClient _apiClient = ApiClient();

  Future<List<GoalModel>> getGoals() async {
    try {
      final response = await _apiClient.dio.get(ApiEndpoints.goals);
      final List<dynamic> data = response.data;
      return data.map((json) => GoalModel.fromJson(json)).toList();
    } on DioException catch (e) {
      final message = e.response?.data['detail'] ?? 'Error al obtener metas';
      throw Exception(message);
    }
  }

  Future<GoalModel> createGoal(GoalModel goal) async {
    try {
      final response = await _apiClient.dio.post(
        ApiEndpoints.goals,
        data: goal.toCreateJson(),
      );
      return GoalModel.fromJson(response.data);
    } on DioException catch (e) {
      final message = e.response?.data['detail'] ?? 'Error al crear meta';
      throw Exception(message);
    }
  }

  Future<GoalModel> updateGoal({
    required int goalId,
    String? nombre,
    double? montoObjetivo,
    DateTime? fechaLimite,
    String? categoria,
    bool? recordatorio,
  }) async {
    try {
      // `fecha_limite` se envía siempre (null la limpia); el resto solo si cambia.
      final data = <String, dynamic>{
        'fecha_limite': fechaLimite?.toIso8601String().split('T')[0],
      };
      if (nombre != null) data['nombre'] = nombre;
      if (montoObjetivo != null) data['monto_objetivo'] = montoObjetivo;
      if (categoria != null) data['categoria'] = categoria;
      if (recordatorio != null) data['recordatorio'] = recordatorio;

      final response = await _apiClient.dio.put(
        ApiEndpoints.goalById(goalId),
        data: data,
      );
      return GoalModel.fromJson(response.data);
    } on DioException catch (e) {
      final message = e.response?.data['detail'] ?? 'Error al actualizar meta';
      throw Exception(message);
    }
  }

  Future<List<GoalContributionModel>> getContributions(int goalId) async {
    try {
      final response =
          await _apiClient.dio.get(ApiEndpoints.contributionsGoal(goalId));
      final List<dynamic> data = response.data;
      return data.map((json) => GoalContributionModel.fromJson(json)).toList();
    } on DioException catch (e) {
      final message =
          e.response?.data['detail'] ?? 'Error al obtener el historial de aportes';
      throw Exception(message);
    }
  }

  Future<ContributeResult> contributeToGoal(
    int goalId,
    double amount, {
    DateTime? fecha,
    String? descripcion,
  }) async {
    try {
      final data = <String, dynamic>{'monto': amount};
      if (fecha != null) {
        data['fecha'] = fecha.toIso8601String().split('T')[0]; // yyyy-MM-dd
      }
      if (descripcion != null && descripcion.trim().isNotEmpty) {
        data['descripcion'] = descripcion.trim();
      }
      final response = await _apiClient.dio.post(
        ApiEndpoints.contributeGoal(goalId),
        data: data,
      );
      return ContributeResult.fromJson(response.data);
    } on DioException catch (e) {
      final message = e.response?.data['detail'] ?? 'Error al realizar aportación';
      throw Exception(message);
    }
  }

  /// Simula un aporte (sin guardarlo) para mostrar el impacto real en el
  /// SmartScore en la pantalla de Confirmar aporte.
  Future<ContributePreview> previewContribution(int goalId, double amount) async {
    try {
      final response = await _apiClient.dio.post(
        ApiEndpoints.contributePreviewGoal(goalId),
        data: {'monto': amount},
      );
      return ContributePreview.fromJson(response.data);
    } on DioException catch (e) {
      final message =
          e.response?.data['detail'] ?? 'Error al calcular el impacto del aporte';
      throw Exception(message);
    }
  }

  Future<void> deleteGoal(int goalId) async {
    try {
      await _apiClient.dio.delete(ApiEndpoints.goalById(goalId));
    } on DioException catch (e) {
      final message = e.response?.data['detail'] ?? 'Error al eliminar meta';
      throw Exception(message);
    }
  }
}
