import 'package:dio/dio.dart';
import '../../core/constants/api_endpoints.dart';
import '../models/alert_model.dart';
import 'api_client.dart';

class AlertService {
  final ApiClient _apiClient = ApiClient();

  Future<List<AlertModel>> getAlerts() async {
    try {
      final response = await _apiClient.dio.get(ApiEndpoints.alerts);
      final List<dynamic> data = response.data;
      return data.map((json) => AlertModel.fromJson(json)).toList();
    } on DioException catch (e) {
      final message = e.response?.data['detail'] ?? 'Error al obtener notificaciones';
      throw Exception(message);
    }
  }

  Future<void> generateAlerts() async {
    try {
      await _apiClient.dio.post(ApiEndpoints.generateAlerts);
    } on DioException catch (e) {
      final message = e.response?.data['detail'] ?? 'Error al evaluar alertas';
      throw Exception(message);
    }
  }

  Future<AlertModel> markAsRead(int alertId) async {
    try {
      final response = await _apiClient.dio.put(ApiEndpoints.readAlert(alertId));
      return AlertModel.fromJson(response.data);
    } on DioException catch (e) {
      final message = e.response?.data['detail'] ?? 'Error al marcar notificación como leída';
      throw Exception(message);
    }
  }
}
