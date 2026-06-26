import 'package:dio/dio.dart';
import '../../core/constants/api_endpoints.dart';
import '../models/profile_summary_model.dart';
import 'api_client.dart';

class ProfileService {
  final ApiClient _apiClient = ApiClient();

  /// Métricas reales del "Resumen personal" de Perfil (1A) en una sola llamada.
  Future<ProfileSummary> getSummary() async {
    try {
      final response = await _apiClient.dio.get(ApiEndpoints.profileSummary);
      return ProfileSummary.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      final message =
          e.response?.data['detail'] ?? 'Error al obtener el resumen de perfil';
      throw Exception(message);
    }
  }
}
