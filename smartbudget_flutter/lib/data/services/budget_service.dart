import 'package:dio/dio.dart';
import '../../core/constants/api_endpoints.dart';
import '../models/budget_model.dart';
import 'api_client.dart';

class BudgetService {
  final ApiClient _apiClient = ApiClient();

  Future<BudgetModel> getCurrentBudget() async {
    try {
      final response = await _apiClient.dio.get(ApiEndpoints.currentBudget);
      return BudgetModel.fromJson(response.data);
    } on DioException catch (e) {
      final message = e.response?.data['detail'] ?? 'Error al obtener presupuesto mensual';
      throw Exception(message);
    }
  }

  Future<BudgetModel> createBudget(double montoBase, int mes, int anio) async {
    try {
      final response = await _apiClient.dio.post(
        ApiEndpoints.createBudget,
        data: {
          'monto_base': montoBase,
          'mes': mes,
          'año': anio,
        },
      );
      return BudgetModel.fromJson(response.data);
    } on DioException catch (e) {
      final message = e.response?.data['detail'] ?? 'Error al crear presupuesto';
      throw Exception(message);
    }
  }

  Future<BudgetModel> addIncome(double monto, String descripcion) async {
    try {
      final response = await _apiClient.dio.post(
        ApiEndpoints.addIncome,
        data: {
          'monto': monto,
          'descripcion': descripcion,
        },
      );
      return BudgetModel.fromJson(response.data);
    } on DioException catch (e) {
      final message = e.response?.data['detail'] ?? 'Error al registrar ingreso';
      throw Exception(message);
    }
  }
}
