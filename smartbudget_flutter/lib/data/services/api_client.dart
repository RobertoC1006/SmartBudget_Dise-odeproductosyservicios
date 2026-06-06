import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants/api_endpoints.dart';

class ApiClient {
  static final ApiClient _instance = ApiClient._internal();
  factory ApiClient() => _instance;

  final Dio dio;
  static const String _tokenKey = 'auth_token';
  void Function()? onUnauthorized;

  ApiClient._internal()
      : dio = Dio(
          BaseOptions(
            baseUrl: ApiEndpoints.baseUrl,
            connectTimeout: const Duration(seconds: 10),
            receiveTimeout: const Duration(seconds: 10),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
          ),
        ) {
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          // Dynamic baseUrl lookup in case the device platform was detected differently
          options.baseUrl = ApiEndpoints.baseUrl;
          
          final prefs = await SharedPreferences.getInstance();
          final token = prefs.getString(_tokenKey);
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          return handler.next(options);
        },
        onError: (DioException error, handler) async {
          if (error.response?.statusCode == 401) {
            final prefs = await SharedPreferences.getInstance();
            await prefs.remove(_tokenKey);
            if (onUnauthorized != null) {
              onUnauthorized!();
            }
          }
          return handler.next(error);
        },
      ),
    );
  }

  Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
  }

  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  Future<void> clearToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
  }

  Future<bool> hasToken() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_tokenKey);
    return token != null && token.isNotEmpty;
  }
}
