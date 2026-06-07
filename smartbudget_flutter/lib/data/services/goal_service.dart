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
        data: goal.toJson(),
      );
      return GoalModel.fromJson(response.data);
    } on DioException catch (e) {
      final message = e.response?.data['detail'] ?? 'Error al crear meta';
      throw Exception(message);
    }
  }

  Future<GoalModel> contributeToGoal(int goalId, double amount) async {
    try {
      final response = await _apiClient.dio.post(
        ApiEndpoints.contributeGoal(goalId),
        queryParameters: {'monto': amount},
      );
      return GoalModel.fromJson(response.data);
    } on DioException catch (e) {
      final message = e.response?.data['detail'] ?? 'Error al realizar aportación';
      throw Exception(message);
    }
  }

  Future<void> deleteGoal(int goalId) async {
    try {
      await _apiClient.dio.delete('${ApiEndpoints.goals}$goalId');
    } on DioException catch (e) {
      final message = e.response?.data['detail'] ?? 'Error al eliminar meta';
      throw Exception(message);
    }
  }
}
