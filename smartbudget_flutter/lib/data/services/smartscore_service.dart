import 'package:dio/dio.dart';
import '../../core/constants/api_endpoints.dart';
import '../models/smartscore_model.dart';
import 'api_client.dart';

class SmartScoreService {
  final ApiClient _apiClient = ApiClient();

  Future<int> getCurrentScore() async {
    try {
      final response = await _apiClient.dio.get(ApiEndpoints.smartScore);
      final model = SmartScoreModel.fromJson(response.data);
      return model.score;
    } on DioException catch (e) {
      final message = e.response?.data['detail'] ?? 'Error al obtener puntuación';
      throw Exception(message);
    }
  }

  /// Score completo con el desglose por criterio (presupuesto/metas/alertas/ahorro).
  Future<SmartScoreModel> getScore() async {
    try {
      final response = await _apiClient.dio.get(ApiEndpoints.smartScore);
      return SmartScoreModel.fromJson(response.data);
    } on DioException catch (e) {
      final message = e.response?.data['detail'] ?? 'Error al obtener puntuación';
      throw Exception(message);
    }
  }

  Future<List<SmartScoreSnapshotModel>> getScoreHistory({int meses = 6}) async {
    try {
      final response = await _apiClient.dio.get(
        ApiEndpoints.smartScoreHistory,
        queryParameters: {'meses': meses},
      );
      final List<dynamic> data = response.data;
      return data.map((json) => SmartScoreSnapshotModel.fromJson(json)).toList();
    } on DioException catch (e) {
      final message = e.response?.data['detail'] ?? 'Error al obtener historial de puntuación';
      throw Exception(message);
    }
  }
}
