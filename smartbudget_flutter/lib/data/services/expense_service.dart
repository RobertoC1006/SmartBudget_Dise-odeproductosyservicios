// ignore_for_file: use_null_aware_elements

import 'dart:typed_data';

import 'package:dio/dio.dart';
import '../../core/constants/api_endpoints.dart';
import '../models/expense_model.dart';
import 'api_client.dart';

class ExpenseService {
  final ApiClient _apiClient = ApiClient();

  Future<List<ExpenseModel>> getExpenses({int? mes, int? anio, String? categoria}) async {
    try {
      final response = await _apiClient.dio.get(
        ApiEndpoints.expenses,
        queryParameters: {
          if (mes != null) 'mes': mes,
          if (anio != null) 'año': anio,
          if (categoria != null) 'categoria': categoria,
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

  Future<Map<String, dynamic>> scanReceipt(
    Uint8List bytes, {
    required String filename,
    String? mimeType,
  }) async {
    try {
      final formData = FormData.fromMap({
        'file': MultipartFile.fromBytes(
          bytes,
          filename: filename,
          contentType: DioMediaType.parse(mimeType ?? _mimeFromFilename(filename)),
        ),
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

  // El backend reenvía el content-type al modelo de visión, por lo que no
  // puede llegar como application/octet-stream.
  String _mimeFromFilename(String filename) {
    final ext = filename.split('.').last.toLowerCase();
    switch (ext) {
      case 'png':
        return 'image/png';
      case 'webp':
        return 'image/webp';
      case 'heic':
      case 'heif':
        return 'image/heic';
      default:
        return 'image/jpeg';
    }
  }
}
