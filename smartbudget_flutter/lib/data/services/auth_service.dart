import 'package:dio/dio.dart';
import '../../core/constants/api_endpoints.dart';
import '../models/user_model.dart';
import 'api_client.dart';

class AuthService {
  final ApiClient _apiClient = ApiClient();

  Future<String> login(String email, String password) async {
    try {
      final response = await _apiClient.dio.post(
        ApiEndpoints.login,
        data: {
          'username': email,
          'password': password,
        },
        options: Options(
          contentType: Headers.formUrlEncodedContentType,
        ),
      );

      final token = response.data['access_token'] as String;
      await _apiClient.saveToken(token);
      return token;
    } on DioException catch (e) {
      final message = e.response?.data['detail'] ?? 'Error de inicio de sesión';
      throw Exception(message);
    }
  }

  Future<UserModel> register({
    required String nombre,
    required String email,
    required String password,
    String? ocupacion,
  }) async {
    try {
      final body = {
        'nombre': nombre,
        'email': email,
        'password': password,
        ...?ocupacion != null ? {'ocupacion': ocupacion} : null,
      };
      final response = await _apiClient.dio.post(ApiEndpoints.register, data: body);
      return UserModel.fromJson(response.data);
    } on DioException catch (e) {
      final message = e.response?.data['detail'] ?? 'Error al registrar usuario';
      throw Exception(message);
    }
  }

  Future<UserModel> updateOcupacion(String ocupacion) async {
    try {
      final response = await _apiClient.dio.patch(
        ApiEndpoints.updateMe,
        data: {'ocupacion': ocupacion},
      );
      return UserModel.fromJson(response.data);
    } on DioException catch (e) {
      final message = e.response?.data['detail'] ?? 'Error al actualizar perfil';
      throw Exception(message);
    }
  }

  Future<UserModel> getMe() async {
    try {
      final response = await _apiClient.dio.get(ApiEndpoints.me);
      return UserModel.fromJson(response.data);
    } on DioException catch (e) {
      final message = e.response?.data['detail'] ?? 'Error al obtener datos de perfil';
      throw Exception(message);
    }
  }
}
