// ignore_for_file: use_null_aware_elements

import 'package:dio/dio.dart';
import '../../core/constants/api_endpoints.dart';
import '../models/expense_model.dart';
import 'api_client.dart';

class ExpenseService {
  final ApiClient _apiClient = ApiClient();

  Future<List<ExpenseModel>> getExpenses({int? mes, int? anio}) async {
    try {
      final response = await _apiClient.dio.get(
        ApiEndpoints.expenses,
        queryParameters: {
          if (mes != null) 'mes': mes,
          if (anio != null) 'año': anio,
        },
      );
      final List<dynamic> data = response.data;
      return data.map((json) => ExpenseModel.fromJson(json)).toList();
    } on DioException catch (e) {
      final message = e.response?.data['detail'] ?? 'Error al obtener transacciones';
      throw Exception(message);
    }
  }

  Future<ExpenseModel> createExpense(ExpenseModel expense) async {
    try {
      final response = await _apiClient.dio.post(
        ApiEndpoints.expenses,
        data: expense.toJson(),
      );
      return ExpenseModel.fromJson(response.data);
    } on DioException catch (e) {
      final message = e.response?.data['detail'] ?? 'Error al registrar gasto';
      throw Exception(message);
    }
  }

  Future<void> deleteExpense(int expenseId) async {
    try {
      await _apiClient.dio.delete('${ApiEndpoints.expenses}$expenseId');
    } on DioException catch (e) {
      final message = e.response?.data['detail'] ?? 'Error al eliminar gasto';
      throw Exception(message);
    }
  }

  Future<Map<String, dynamic>> scanReceipt(String filePath) async {
    try {
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(filePath),
      });

      final response = await _apiClient.dio.post(
        ApiEndpoints.scanExpense,
        data: formData,
      );

      return response.data;
    } on DioException catch (e) {
      final message = e.response?.data['detail'] ?? 'Error al escanear comprobante';
      throw Exception(message);
    }
  }
}
